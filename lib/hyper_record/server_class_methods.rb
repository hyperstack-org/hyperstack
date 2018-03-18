module HyperRecord
  module ServerClassMethods
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
      @rest_methods_hash ||= {}
    end
  end
end