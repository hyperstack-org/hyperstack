module Hyperstack
  module Params
    module ClassMethods
      def validator
        @validator ||= Hyperstack::Validator.new
      end

      def param(*args)
        if args[0].is_a? Hash
          options = args[0]
          name = options.first[0]
          default = options.first[1]
          options.delete(name)
          options.merge!({default: default})
        else
          name = args[0]
          options = args[1] || {}
        end
        if options[:default]
          validator.optional(name, options)
        else
          validator.requires(name, options)
        end
      end

      def default_props
        validator.default_props
      end

      def params(&block)
        validator.build(&block)
      end

      def collect_other_params_as(name)
        validator.allow_undefined_props = true
        validator_in_lexical_scope = validator
        validator.props_wrapper.define_method(name) do
          @_all_others ||= validator_in_lexical_scope.undefined_props(props)
        end

        validator_in_lexial_scope = validator
        validator.props_wrapper.define_method(name) do
          @_all_others ||= validator_in_lexial_scope.undefined_props(props)
        end
      end
    end
  end
end
