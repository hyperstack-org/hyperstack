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
          self.class.load_data do
            hash.each do |attribute, value|
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

    def method_missing(name, *args, &block)
      if name =~ /\!$/
        name = name.gsub(/\!$/,"")
        force_update = true
      end
      if name =~ /_changed\?$/
        @backing_record.changed?(name.gsub(/_changed\?$/,""))
      elsif args.count == 1 && name =~ /=$/ && !block
        attribute_name = name.gsub(/=$/,"")
        @backing_record.reactive_set!(attribute_name, args[0])
      elsif args.count == 0 && !block
        @backing_record.reactive_get!(name, force_update)
      elsif !block
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
        results = yield *results if block
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
      @backing_record.destroy &block
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

  end

end
