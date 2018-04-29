module HyperRecord
  module ServerClassMethods
    def rest_class_method(name, options = { default_result: '...' }, &block)
      rest_methods[name] = options
      rest_methods[name][:params] = block.arity
      rest_methods[name][:class_method] = true
      singleton_class.send(:define_method, name) do |*args|
        if args.size > 0
          block.call(*args)
        else
          block.call
        end
      end
    end

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

    def rest_methods
      @rest_methods ||= {}
    end

    def resource_scopes
      @resource_scopes ||= []
    end

    def scope(name, *args)
      resource_scopes << name
      super(name, *args)
    end
  end
end