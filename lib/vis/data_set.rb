module Vis
  class DataSet
    include Native
    include Vis::Utilities
    include Vis::EventSupport
    include Vis::DataCommon

    aliases_native %i[clear distinct flush length]
    native_method_with_options :setOptions
    alias :size :length
    
    attr_reader :event_handlers

    def self.wrap(native)
      instance = allocate
      instance.instance_variable_set(:@native, native)
      instance
    end

    def initialize(*args)
      if args[0] && `Opal.is_a(args[0], Opal.Hash)`
        hash_array = []
        options = args[0]
      elsif args[0] && `Opal.is_a(args[0], Opal.Array)`
        hash_array = args[0]
        options = args[1] ? args[1] : {}
      else
        hash_array = []
        options = {}
      end
      native_data = hash_array_to_native(hash_array)
      native_options = options_to_native(options)
      @event_handlers = {}
      @native = `new vis.DataSet(native_data, native_options)`
    end

    def []=(id, hash)
      if get(id)
        update(hash[:id] = id)
      else
        add(hash[:id] = id)
      end
    end

    def add(*args)
      if args[0] && `Opal.is_a(args[0], Opal.Hash)`
        args[0] = args[0].to_n
      elsif args[0] && `Opal.is_a(args[0], Opal.Array)`
        args[0] = hash_array_to_native(args[0])
      end
      `self["native"].add.apply(self["native"], Opal.to_a(args))`
    end

    def each(options = nil, &block)
      native_options = options_to_native(options)
      `return self["native"].forEach(function(item) { return block.$call(Opal.Hash.$new(item)); }, native_options)`
    end

    def get_data_set
      self
    end

    def map(options = nil, &block)
      native_options = options_to_native(options)
      `return self["native"].map(function(item) { return #{block.call(`Opal.Hash.$new(item)`)}; }, native_options)`
    end

    def max(field)
      res = @native.JS.max(field)
      `res !== null ? Opal.Hash.$new(res) : #{nil}`
    end
    
    def min(field)
      res = @native.JS.min(field)
      `res !== null ? Opal.Hash.$new(res) :  #{nil}`
    end

    def remove(*args)
      if `Opal.is_a(args[0], Opal.Array)`
        args[0] = hash_array_to_native(args[0])
      elsif `Opal.is_a(args[0], Opal.Hash)`
        args[0] = args[0].to_n
      end
      `self["native"].remove.apply(self["native"], Opal.to_a(args))`
    end

    def update(*args)
      if args[0] && `Opal.is_a(args[0], Opal.Hash)`
        args[0] = args[0].to_n
      elsif args[0] && `Opal.is_a(args[0], Opal.Array)`
        args[0] = hash_array_to_native(args[0])
      end
      `self["native"].update.apply(self["native"], Opal.to_a(args))`
    end
  end
end