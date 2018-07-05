module HyperRecord
  module ServerClassMethods
    # DSL for defining rest_class_methods
    # @param name [Symbol] name of the method
    # @param options [Hash] known key: default_result, used client side
    def rest_class_method(name, options = { default_result: '...' }, &block)
      rest_class_methods[name] = options
      rest_class_methods[name][:params] = block.arity
      singleton_class.send(:define_method, name) do |*args|
        if args.size > 0
          block.call(*args)
        else
          block.call
        end
      end
    end

    # DSL for defining rest_methods
    # @param name [Symbol] name of the method
    # @param options [Hash] known key: default_result, used client side
    def rest_method(name, options = { default_result: '...' }, &block)
      rest_methods[name] = options
      rest_methods[name][:params] = block.arity
      define_method(name) do |*args|
        if args.size > 0
          instance_exec(*args, &block)
        else
          instance_exec(&block)
        end
      end
    end

    # introspect defined rest_class_methods
    # @return [Hash]
    def rest_class_methods
      @rest_class_methods ||= {}
    end

    # introspect defined rest_methods
    # @return [Hash]
    def rest_methods
      @rest_methods ||= {}
    end

    # introspect defined scopes
    # @return [Hash]
    def resource_scopes
      @resource_scopes ||= {}
    end

    # defines a scope, wrapper around ORM method
    # @param name [Symbol] name of the args
    # @param *args additional args, passed to ORMs scope DSL
    def scope(name, *args)
      resource_scopes[name] = args
      super(name, *args)
    end
  end
end