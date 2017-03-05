module HyperStore
  class MutatorWrapper < BasicObject

    class << self
      def add_method(klass, method_name, opts = {})
        define_method(:"#{method_name}") do |*args|
          from = opts[:scope] == :shared ? klass.state.__from__ : __from__
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

        initialize_values(klass, method_name, opts) if initialize_values?(opts)
      end

      def initialize_values?(opts)
        [:class, :shared].include?(opts[:scope]) && (opts[:initializer] || opts[:block])
      end

      def initialize_values(klass, name, opts)
        initializer = initializer_proc(opts[:initializer], klass, name) if opts[:initializer]

        if initializer && opts[:block]
          klass.receives(Hyperloop::Application::Boot, initializer) do
            klass.mutate.send(:"#{name}", opts[:block].call)
          end
        elsif initializer
          klass.receives(Hyperloop::Application::Boot, initializer)
        elsif opts[:block]
          klass.receives(Hyperloop::Application::Boot) do
            klass.mutate.send(:"#{name}", opts[:block].call)
          end
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

    attr_accessor :__from__

    # def self.new(from)
    #   instance = allocate
    #   instance.__from__ = from
    #   instance
    # end

    def initialize(from)
      __from__ = from
    end

    def __class__
      (class << self; self end).superclass
    end

    # Any method_missing call will create a state and accessor with that name
    def method_missing(name, *args, &block) # rubocop:disable Style/MethodMissing
      self.class.add_method(nil, name)
      send(name, *args, &block)
    end
  end
end
