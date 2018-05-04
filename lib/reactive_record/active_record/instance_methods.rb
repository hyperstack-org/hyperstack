module ActiveRecord
  module InstanceMethods
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
      @backing_record == ar_instance.instance_eval { @backing_record }
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

    def new?
      @backing_record.new?
    end

    def errors
      React::State.get_state(@backing_record, @backing_record)
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
