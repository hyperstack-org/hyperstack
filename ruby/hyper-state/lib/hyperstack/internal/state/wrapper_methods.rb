module Hyperstack
  module Internal
    class State
      module WrapperMethods
        def define_state_methods(klass, default_scope, *args, &block)
          name, opts = validate_args!(klass, default_scope, *args, &block)
          add_readers(klass, name, opts)
          add_methods(klass, name, opts)
        end

        def validate_args!(klass, default_scope, *args, &block)
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
            if [:reader, :initializer, :scope].include?(args.first.keys.first.to_sym)
              message = 'The name of the state must be specified first as '\
                        "either 'state :name' or 'state name: <initial value>'"
              invalid_option(message)
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
          invalid_option("states can only have one form of initializer") if initializer
        end

        def validate_initializer(initial_value, opts, block) # rubocop:disable Metrics/MethodLength
          initializer = block if block

          # If we pass in the name as a hash with a value ex: state foo: :bar,
          # we just put that value inside a Proc and return that

          if initial_value != nil
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
            invalid_option("The reader for the state cannot be the same as the name")
          end

          if [:instance, :shared].include?(opts[:scope])
            klass.define_method(:"#{opts[:reader]}") { send(:"#{name}").state }
          end

          if [:class, :shared].include?(opts[:scope])
            klass.define_singleton_method(:"#{opts[:reader]}") { send(:"#{name}").state }
          end
        end

        def add_methods(klass, name, opts)
          if opts[:scope] == :instance
            klass.send(:define_method, name) { __hyperstack_states[name] ||= State.new(self, name, opts[:initializer]) }
          else
            klass.instance_eval do # https://www.jimmycuadra.com/posts/metaprogramming-ruby-class-eval-and-instance-eval/
              define_singleton_method(name) { __hyperstack_states[klass][name] ||= State.new(self, name, opts[:initializer]) }
            end
          end
          klass.define_method(name) { klass.send(name) } if opts[:shared]
        end
      end
    end
  end
end
