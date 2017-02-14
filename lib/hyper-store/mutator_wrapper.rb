module HyperStore
  class MutatorWrapper
    attr_reader :from

    class << self
      def add_method(klass, method_name, opts = {})
        define_method(:"#{method_name}") do |*args|
          from = opts[:scope] == :shared ? klass.state.from : @from
          current_value = React::State.get_state(from, method_name.to_s)

          if args.count > 0
            React::State.set_state(from, method_name.to_s, args[0])
            current_value
          else
            React::State.set_state(from, method_name.to_s, current_value)
            React::Observable.new(current_value) do |update|
              React::State.set_state(from, method_name.to_s, update)
            end
          end
        end

        if [:class, :shared].include?(opts[:scope]) && (opts[:initializer] || opts[:block])
          initialize_values(klass, method_name, opts)
        end
      end

      def initialize_values(klass, name, opts)
        initializer = initializer_proc(opts[:initializer], klass, name) if opts[:initializer]

        if initializer && opts[:block]
          klass.receives(HyperLoop::Boot, initializer) do
            klass.mutate.send(:"#{name}", opts[:block].call)
          end
        elsif initializer
          klass.receives(HyperLoop::Boot, initializer)
        elsif opts[:block]
          klass.receives(HyperLoop::Boot) { klass.mutate.send(:"#{name}", opts[:block].call) }
        end
      end

      private

      def initializer_proc(initializer, klass, name)
        # We gotta check the arity because a Proc passed in directly from initializer has no args,
        # but if we created one then we might have wanted the class
        if initializer.arity > 0
          -> { klass.mutate.send(:"#{name}", initializer.call(klass)) }
        else
          -> { klass.mutate.send(:"#{name}", initializer.call) }
        end
      end
    end

    def initialize(from)
      @from = from
    end

    def method_missing(name, *args, &block)
      self.class.add_method(nil, name)
      send(name, *args, &block)

      super
    end

    def respond_to_missing?(method_name, include_private = false)
      super
    end
  end
end
