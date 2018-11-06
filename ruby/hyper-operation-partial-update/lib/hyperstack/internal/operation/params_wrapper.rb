module Hyperstack
  module Internal
    module Operation
      class ParamsWrapper

        def initialize(inputs)
          @inputs = inputs
        end

        def lock
          @locked = true
          self
        end

        def to_h
          inputs = @inputs
          if @locked
            inputs = inputs.dup
            self.class.inbound_params.each { |name| inputs.delete :"#{name}" }
          end
          inputs.with_indifferent_access
        end

        def to_s
          to_h.to_s
        end

        class << self

          def combine_arg_array(args)
            hash = args.inject({}.with_indifferent_access) do |h, arg|
              raise ArgumentError.new("All arguments must be hashes") unless arg.respond_to? :to_h
              h.merge!(arg.to_h)
            end
          end

          def process_params(operation, args)
            raw_inputs = combine_arg_array(args)
            inputs, errors = hash_filter.filter(raw_inputs)
            params_wrapper = new(inputs)
            operation.instance_eval do
              @raw_inputs, @params, @errors = [raw_inputs, params_wrapper, errors]
            end
          end

          def add_param(*args, &block)
            type_method, name, opts, block = translate_args(*args, &block)
            inbound_params << :"#{name}" if opts.delete(:inbound)
            if opts.key? :default
              hash_filter.optional { send(type_method, name, opts, &block) }
            else
              hash_filter.required { send(type_method, name, opts, &block) }
            end

            # don't forget specially handling for procs
            define_method(name) do
              @inputs[name]
            end
            define_method(:"#{name}=") do |x|
              method_missing(:"#{name}=", x) if @locked
              @inputs[name] = x
            end
          end

          def dispatch_params(params, hashes = {})
            params = params.dup
            hashes.each { |hash| hash.each { |k, v| params.send(:"#{k}=", v) } }
            params.lock
          end

          def hash_filter
            # the :duck method is added in lib/hyper-operation.rb globally
            @hash_filter ||= Mutations::HashFilter.new
          end

          def inbound_params
            @inbound_params ||= Set.new
          end

          def translate_args(*args, &block)
            name, opts = get_name_and_opts(*args)
            if opts.key?(:type)
              type_method = opts.delete(:type)
              if type_method.is_a?(Array)
                opts[:class] = type_method.first if type_method.count > 0
                type_method = Array
              elsif type_method.is_a?(Hash) || type_method == Hash
                type_method = Hash
                block ||= proc { duck :* }
              end
              type_method = type_method.to_s.underscore
            else
              type_method = :duck
            end
            [type_method, name, opts, block || proc {}]
          end

          def get_name_and_opts(*args)
            if args[0].is_a? Hash
              opts = args[0]
              name = opts.first.first
              opts[:default] = opts.first.last
              opts.delete(name)
            else
              name = args[0]
              opts = args[1] || {}
            end
            [name, opts]
          end
        end
      end
    end
  end
end
