module Hyperstack
  module Internal
    module State
      module Wrapper
        extend ProcessArgs
        class << self
          def define_wrapper_methods(base)
            %i[singleton_method method].each do |kind|
              %i[observe mutate].each do |method|
                base.send(:"define_#{kind}", method) do |&block|
                  result = block.call if block
                  Mapper.send(:"#{method}d!", self)
                  result
                end
              end
            end
          end

          def define_state_methods(klass, default_scope, *args, &block)
            name, opts = process_args!(default_scope, *args, &block)
            binding.pry if default_scope == :class or name == :class_s
            add_readers(klass, name, opts)
            add_methods(klass, name, opts)
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
              add_instance_method(klass, name, &opts[:initializer])
            else
              add_singleton_method(klass, name, &opts[:initializer])
            end
            klass.send('define_method', name) { klass.send(name) } if opts[:scope] == :shared
          end

          def add_instance_method(klass, name, &init)
            var_name = :"@__hyperstack_state_variable_#{name}"
            klass.send(:define_method, name) do
              instance_variable_get(var_name) ||
                instance_variable_set(
                  var_name,
                  Hyperstack::State::Variable.new(
                    init && send(:"instance_#{init.lambda? ? :exec : :eval}", &init)
                  )
                )
            end
          end

          def add_singleton_method(klass, name, &init)
            var_name = :"@__hyperstack_state_variable_#{name}"
            klass.instance_eval do # https://www.jimmycuadra.com/posts/metaprogramming-ruby-class-eval-and-instance-eval/
              define_singleton_method(name) do
                Hyperstack::Context.set_var(klass, var_name) do
                  Hyperstack::State::Variable.new(
                    init && send(:"instance_#{init.lambda? ? :exec : :eval}", &init)
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
