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

        if [:class, :shared].include?(opts[:scope]) && opts[:initialize] || opts[:block]
          initialize_values(klass, method_name, opts)
        end
      end

      def initialize_values(klass, name, opts)
        # First initialize value from initialize Proc
        klass.mutate.send(:"#{name}", opts[:initialize].call(klass))

        # Then call the block if a block is passed
        klass.instance_eval(&opts[:block]) if opts[:block]
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
