module HyperStore
  class StateWrapper
    module ArgumentValidator
      def validate_args!(klass, *args, &block)
        name, initial_value, opts = parse_arguments(*args, &block)

        opts[:scope]    ||= default_scope(klass)
        opts[:reader]     = name if opts[:reader] && opts[:reader].is_a?(Boolean)
        opts[:initialize] = validate_initialize(initial_value, opts)
        opts[:block]      = block if block

        [name, opts]
      end

      private

      def invalid_option(message)
        React::IsomorphicHelpers.log(message, :error)
      end

      # Parses the arguments given to get the name, initial_value (if any), and options
      def parse_arguments(*args)
        # If the only argument is a hash, the first key => value is name => inital_value
        if args.first.is_a?(Hash)
          name, initial_value = args[0].shift
        # Otherwise just the name is passed in by itself first
        else
          name = args.shift
        end

        # [name, initial_value (can be nil), args (if nil then return an empty hash)]
        [name, initial_value, args[0] || {}]
      end

      # Converts the initialize option to a Proc
      def validate_initialize(initial_value, opts) # rubocop:disable Metrics/MethodLength
        # If we pass in the name as a hash with a value ex: state foo: :bar,
        # we just put that value inside a Proc and return that
        if initial_value
          -> { initial_value }
        # If we pass in the initialize option
        elsif opts[:initialize]
          # If it's a Symbol we convert to to a Proc that calls the method on the instance
          if opts[:initialize].is_a?(String)
            method_name = opts[:initialize]
            ->(instance) { instance.send(:"#{method_name}") }
          # If it is already a Proc we do nothing and just return what was given
          elsif opts[:initialize].is_a?(Proc)
            opts[:initialize]
          # If it's not a Proc or a String we raise an error and return an empty Proc
          else
            invalid_option("'state' option 'initialize' must either be a Symbol or a Proc")
            -> {}
          end
        # Otherwise if it's not specified we just return an empty Proc
        else
          -> {}
        end
      end
    end
  end
end
