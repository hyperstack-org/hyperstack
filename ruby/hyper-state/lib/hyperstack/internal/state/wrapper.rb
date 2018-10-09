module Hyperstack
  module Internal
    module State
      module Wrapper
        def define_state_methods(klass, default_scope, *args, &block)
          name, opts = validate_args!(default_scope, *args, &block)
          add_readers(klass, name, opts)
          add_methods(klass, name, opts)
        end

        def validate_args!(default_scope, *args, &block)
          name, initial_value, opts = parse_arguments(*args, &block)

          opts[:scope]     ||= default_scope
          opts[:initializer] = validate_initializer(initial_value, opts, block)
          return [name, opts] if name != :state || scope != :instance
          invalid_option('Cannot name a class state "state" as this will override the state macro.')
        end

        def invalid_option(message)
          raise Hyperstack::State::InvalidOptionError, message
        end

        # Parses the arguments given to get the name, initial_value (if any), and options
        def parse_arguments(*args)
          # If the only argument is a hash, the first key => value is name => inital_value
          if args.first.is_a?(Hash)
            # If the first key passed in is not the name, raise an error
            if %i[reader initializer scope].include?(args.first.keys.first.to_sym)
              invalid_option 'The name of the state must be specified first as '\
                             "either 'state :name' or 'state name: <initial value>'"
            end

            name, initial_value = args[0].shift
          # Otherwise just the name is passed in by itself first
          else
            name = args.shift
          end

          # [name, initial_value (can be nil), args (if nil then return an empty hash)]
          [name, initial_value, args[0] || {}]
        end

        # Returns the initialize option as a proc or nil
        def check_too_many_initializers(initializer)
          invalid_option('states can only have one form of initializer') if initializer
        end

        def validate_initializer(initial_value, opts, block) # rubocop:disable Metrics/MethodLength
          initializer = block if block

          # If we pass in the name as a hash with a value ex: state foo: :bar,
          # we just put that value inside a Proc and return that

          unless initial_value.nil?
            check_too_many_initializers(initializer)
            initializer = dup_or_return_initial_value(initial_value)
          end
          return initializer unless opts[:initializer]

          # If we pass in the initialize option

          check_too_many_initializers(initializer)

          # If it's a Symbol we convert to to a Proc that calls the method on the instance
          if opts[:initializer].respond_to? :to_proc
            opts[:initializer].to_proc
          elsif opts[:initializer].is_a? String
            :"#{opts[:initializer]}".to_proc
          # If it's not a Proc or a String we raise an error and return an empty Proc
          else
            invalid_option("'state' option 'initialize' must either be a Symbol or a Proc")
          end
        end

        # Dup the initial value if possible, otherwise just return it
        # Ruby has no nice way of doing this...
        def dup_or_return_initial_value(value)
          value =
            begin
              value.dup
            rescue
              value
            end

          Proc.new { value }
        end

        def add_readers(klass, name, opts)
          return unless opts[:reader]
          if opts[:reader] == name || opts[:reader] == true
            invalid_option('The reader for the state cannot be the same as the name')
          end

          if %i[instance shared].include?(opts[:scope])
            klass.define_method(:"#{opts[:reader]}") { send(:"#{name}").state }
          end

          return unless %i[class shared].include?(opts[:scope])

          klass.define_singleton_method(:"#{opts[:reader]}") { send(:"#{name}").state }
        end

        def add_methods(klass, name, opts)
          if opts[:scope] == :instance
            add_instance_method(klass, name, &opts[initializer])
          else
            add_singleton_method(klass, name, &opts[initializer])
          end
          klass.define_method(name) { klass.send(name) } if opts[:shared]
        end

        def add_instance_method(klass, name, &initializer)
          var_name = :"@__hyperstack_state_variable_#{name}"
          klass.send(:define_method, name) do
            instance_variable_get(var_name) ||
              instance_variable_set(var_name, Hyperstack::State::Variable.new(&initializer))
          end
        end

        def add_singleton_method(klass, name, &initializer)
          var_name = :"@__hyperstack_state_variable_#{name}"
          klass.instance_eval do # https://www.jimmycuadra.com/posts/metaprogramming-ruby-class-eval-and-instance-eval/
            define_singleton_method(name) do
              Hyperstack::Context.set_var(klass, var_name) do
                Hyperstack::State::Variable.new(&initializer)
              end
            end
          end
        end
      end
    end
  end
end
