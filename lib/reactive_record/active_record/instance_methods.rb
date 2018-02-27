module ActiveRecord

  module InstanceMethods

    attr_reader :backing_record

    def attributes
      @backing_record.attributes
    end

    def initialize(hash = {})

      if hash.is_a? ReactiveRecord::Base
        @backing_record = hash
      else
        # standard active_record new -> creates a new instance, primary key is ignored if present
        # we have to build the backing record first then initialize it so associations work correctly
        @backing_record = ReactiveRecord::Base.new(self.class, {}, self)
        @backing_record.instance_eval do
          h = Hash.new
          hash.each { |a, v| h[a] = convert(a, v).itself }
          self.class.load_data do
            h.each do |attribute, value|
              unless attribute == primary_key
                reactive_set!(attribute, value)
                changed_attributes << attribute
              end
            end
            #changed_attributes << primary_key # insures that changed attributes has at least one element
          end
        end
      end
    end

    def primary_key
      self.class.primary_key
    end

    def type
      @backing_record.reactive_get!(:type, nil)
    end

    def type=(val)
      @backing_record.reactive_set!(:type, backing_record.convert(:type, val))
    end

    def id
      @backing_record.reactive_get!(primary_key)
    end

    def id=(value)
      @backing_record.id = value
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

    def method_missing_warning(name)
      @backing_record.deprecation_warning("Server side method #{name} must be defined using the 'server_method' macro.")
    end

    def method_missing(name, *args, &block)
      original_name = name

      if name.end_with?('!')
        name = name.chop # remove '!'
        force_update = true
      end

      chopped_name = name.end_with?('=') ? name.chop : name
      is_server_method = self.class.server_methods.has_key?(chopped_name)
      chopped_name = chopped_name.end_with?('?') ? chopped_name.chop : name
      is_attribute = attributes.has_key?(chopped_name)

      unless is_server_method || is_attribute
        if ReactiveRecord::Base.public_columns_hash.has_key?(self.class.name) && ReactiveRecord::Base.public_columns_hash[self.class.name].has_key?(chopped_name)
          is_attribute = true
        end
        method_missing_warning("#{original_name}(#{args})") unless is_attribute
      end

      if name.end_with?('_changed?')
        @backing_record.changed?(name[0...-9]) # remove '_changed?'
      elsif args.count == 1 && name.end_with?('=') && !block
        attribute_name = name.chop # remove '='
        # for rails auto generated methods for booleans, remove '?' to get the attribute
        attribute_name = attribute_name.chop if !is_server_method && is_attribute && attribute_name.end_with?('?')
        @backing_record.reactive_set!(attribute_name, backing_record.convert(attribute_name, args[0]))
      elsif args.count.zero? && !block
        # for rails auto generated methods for booleans, remove '?' to get the attribute
        name = name.chop if !is_server_method && is_attribute && name.end_with?('?')
        @backing_record.reactive_get!(name, force_update)
      elsif !block
        # for rails auto generated methods for booleans, remove '?' to get the attribute
        name = name.chop if !is_server_method && is_attribute && name.end_with?('?')
        @backing_record.reactive_get!([[name]+args], force_update)
      else
        super
      end
    end

    def itself
      # this is useful when you just want to get a handle on record instance
      # in the ReactiveRecord.load method
      id # force load of id...
      self
    end

    def load(*attributes, &block)
      first_time = true
      ReactiveRecord.load do
        results = attributes.collect { |attr| @backing_record.reactive_get!(attr, first_time) }
        results = yield(*results) if block
        first_time = false
        block.nil? && results.count == 1 ? results.first : results
      end
    end

    def save(opts = {}, &block)
      @backing_record.save(opts.has_key?(:validate) ? opts[:validate] : true, opts[:force], &block)
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

  end

end
