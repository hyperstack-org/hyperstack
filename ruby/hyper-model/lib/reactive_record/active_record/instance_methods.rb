module ActiveRecord
  module InstanceMethods

    # if methods are missing, then they must be a column, which we look up
    # in the columns_hash.

    # For effeciency all attributes will by default have all the methods defined,
    # when the class is loaded.  See define_attribute_methods class method.
    # However a model may override the attribute methods definition, but then call
    # super.  Which will result in the method missing call.

    # When loading data from the server we do NOT want to call overridden methods
    # so we also define a _hyperstack_internal_setter_... method for each attribute
    # as well as for belongs_to relationships, server_methods, and the special
    # type and model_name methods.  See the ClassMethods module for details.

    # meanwhile in Opal 1.0 there is currently an issue where the name of the method
    # does not get passed to method_missing from super.
    # https://github.com/opal/opal/issues/2165
    # So the following hack works around that issue until its fixed.

    %x{
      Opal.orig_find_super_dispatcher = Opal.find_super_dispatcher
      Opal.find_super_dispatcher = function(obj, mid, current_func, defcheck, allow_stubs) {
        Opal.__name_of_super = mid;
        return Opal.orig_find_super_dispatcher(obj, mid, current_func, defcheck, allow_stubs)
      }
    }

    def method_missing(missing, *args, &block)
      missing ||= `Opal.__name_of_super`
      column = self.class.columns_hash.detect { |name, *| missing =~ /^#{name}/ }
      if column
        name = column[0]
        case missing
        when /\!\z/ then @backing_record.get_attr_value(name, true)
        when /\=\z/ then @backing_record.set_attr_value(name, *args)
        when /\_changed\?\z/ then @backing_record.changed?(name)
        when /\?/ then @backing_record.get_attr_value(name, nil).present?
        else @backing_record.get_attr_value(name, nil)
        end
      else
        super
      end
    end

    # ignore load_from_json when it calls _hyperstack_internal_setter_id
    def _hyperstack_internal_setter_id(*); end

    # the system assumes that there is "virtual" model_name and type attribute so
    # we define the internal setter here.  If the user defines some other attributes
    # or uses these names no harm is done since the exact same method would have been
    # defined by the define_attribute_methods class method anyway.
    %i[model_name type].each do |attr|
      define_method("_hyperstack_internal_setter_#{attr}") do |val|
        @backing_record.set_attr_value(:model_name, val)
      end
    end

    def inspect
      "<#{model_name}:#{ReactiveRecord::Operations::Base::FORMAT % to_key} "\
      "(#{ReactiveRecord::Operations::Base::FORMAT % object_id}) "\
      "#{backing_record.inspection_details} >"
    end

    attr_reader :backing_record

    def attributes
      @backing_record.attributes
    end

    def changed_attributes
      backing_record.changed_attributes_and_values
    end

    def changes
      backing_record.changes
    end

    def initialize(hash = {})
      if hash.is_a? ReactiveRecord::Base
        @backing_record = hash
      else
        # standard active_record new -> creates a new instance, primary key is ignored if present
        # we have to build the backing record first then initialize it so associations work correctly
        @backing_record = ReactiveRecord::Base.new(self.class, {}, self)
        if self.class.inheritance_column && !hash.key?(self.class.inheritance_column)
          hash[self.class.inheritance_column] = self.class.name
        end
        @backing_record.instance_eval do
          h = {}
          hash.each do |a, v|
            a = model._dealias_attribute(a)
            h[a] = convert(a, v).itself
          end
          self.class.load_data do
            h.each do |attribute, value|
              next if attribute == primary_key
              @ar_instance[attribute] = value
              changed_attributes << attribute
            end
          end
        end
      end
    end

    def primary_key
      self.class.primary_key
    end

    def id
      @backing_record.get_primary_key_value
    end

    def id=(value)
      @backing_record.id = value
    end

    def id?
      id.present?
    end

    def model_name
      # in reality should return ActiveModel::Name object, blah blah
      self.class.model_name
    end

    def revert
      @backing_record.revert
    end

    def changed?
      @backing_record.changed?
    end

    def dup
      self.class.new(self.attributes)
    end

    def ==(ar_instance)
      return true  if @backing_record == ar_instance.instance_eval { @backing_record }
      return false unless ar_instance.is_a?(ActiveRecord::Base)
      return false if ar_instance.new_record?
      return false unless self.class.base_class == ar_instance.class.base_class
      id == ar_instance.id
    end

    def [](attr)
      send(attr)
    end

    def []=(attr, val)
      send("#{attr}=", val)
    end

    def itself
      # this is useful when you just want to get a handle on record instance
      # in the ReactiveRecord.load method
      id # force load of id...
      # if self.class.columns_hash.keys.include?(self.class.inheritance_column) &&
      #    (klass = self[self.class.inheritance_column]).loaded?
      #   Object.const_get(klass).new(attributes)
      # else
        self
      # end
    end

    def load(*attributes, &block)
      first_time = true
      ReactiveRecord.load do
        results = attributes.collect { |attr| send("#{attr}#{'!' if first_time}") }
        results = yield(*results) if block
        first_time = false
        block.nil? && results.count == 1 ? results.first : results
      end
    end

    def save(opts = {}, &block)
      @backing_record.save_or_validate(true, opts.has_key?(:validate) ? opts[:validate] : true, opts[:force], &block)
    end

    def validate(opts = {}, &block)
      @backing_record.save_or_validate(false, true, opts[:force]).then do
        if block
          yield @backing_record.ar_instance
        else
          @backing_record.ar_instance
        end
      end
    end

    def valid?
      errors.reactive_empty?
    end

    def saving?
      @backing_record.saving?
    end

    def destroy(&block)
      @backing_record.destroy(&block)
    end

    def destroyed?
      @backing_record.destroyed
    end

    def new_record?
      @backing_record.new?
    end

    alias new? new_record?

    def errors
      Hyperstack::Internal::State::Variable.get(@backing_record, @backing_record)
      @backing_record.errors
    end

    def to_key
      @backing_record.object_id
    end

    def update_attribute(attr, value, &block)
      send("#{attr}=", value)
      save(validate: false, &block)
    end

    def update(attrs = {}, &block)
      attrs.each { |attr, value| send("#{attr}=", value) }
      save(&block)
    end

    def <=>(other)
      id.to_i <=> other.id.to_i
    end

    def becomes(klass)
      klass._new_without_sti_type_cast(backing_record)
    end

    def becomes!(klass)
      self[self.class.inheritance_column] = klass.name
      becomes(klass)
    end

    def cast_to_current_sti_type
      @backing_record.set_ar_instance!
    end
  end
end
