module Hyperstack
  module Internal
    module Component
      class Validator

        attr_accessor :errors
        attr_reader :props_wrapper
        private :errors, :props_wrapper

        def copy(new_props_wrapper)
          Validator.new(new_props_wrapper).tap do |c|
            %i[@allow_undefined_props @rules @errors].each do |var|
              c.instance_variable_set(var, instance_variable_get(var).dup)
            end
          end
        end

        def initialize(props_wrapper = Class.new(PropsWrapper))
          @props_wrapper = props_wrapper
        end

        def self.build(&block)
          new.build(&block)
        end

        def build(&block)
          instance_eval(&block)
          self
        end

        def requires(name, options = {})
          options[:required] = true
          define_rule(name, options)
        end

        def optional(name, options = {})
          options[:required] = false
          define_rule(name, options)
        end

        def event(name)
          rules[name] = coerce_native_hash_values(default: nil, type: Proc, allow_nil: true)
        end

        def all_other_params(name)
          @allow_undefined_props = true
          props_wrapper.define_all_others(name) { |props| props.reject { |name, value| rules[name] } }
        end

        def validate(props)
          self.errors = []
          validate_undefined(props) unless allow_undefined_props?
          props = coerce_native_hash_values(defined_props(props))
          validate_required(props)
          props.each do |name, value|
            validate_types(name, value)
            validate_allowed(name, value)
          end
          errors
        end

        def default_props
          rules
            .select {|key, value| value.keys.include?("default") }
            .inject({}) {|memo, (k,v)| memo[k] = v[:default]; memo}
        end

        private

        def defined_props(props)
          props.select { |name| rules.keys.include?(name) }
        end

        def allow_undefined_props?
          !!@allow_undefined_props
        end

        def rules
          @rules ||= { children: { required: false } }
        end

        def define_rule(name, options = {})
          rules[name] = coerce_native_hash_values(options)
          props_wrapper.define_param(name, options[:type], options[:alias])
        end

        def errors
          @errors ||= []
        end

        def validate_types(prop_name, value)
          return unless klass = rules[prop_name][:type]
          if !klass.is_a?(Array)
            allow_nil = !!rules[prop_name][:allow_nil]
            type_check("`#{prop_name}`", value, klass, allow_nil)
          elsif klass.length > 0
            validate_value_array(prop_name, value)
          else
            allow_nil = !!rules[prop_name][:allow_nil]
            type_check("`#{prop_name}`", value, Array, allow_nil)
          end
        end

        def type_check(prop_name, value, klass, allow_nil)
          return if allow_nil && value.nil?
          return if value.is_a?(klass)
          return if klass.respond_to?(:_react_param_conversion) &&
            klass._react_param_conversion(value, :validate_only)
          errors << "Provided prop #{prop_name} could not be converted to #{klass}"
        end

        def validate_allowed(prop_name, value)
          return unless values = rules[prop_name][:values]
          return if values.include?(value)
          errors << "Value `#{value}` for prop `#{prop_name}` is not an allowed value"
        end

        def validate_required(props)
          (rules.keys - props.keys).each do |name|
            next unless rules[name][:required]
            errors << "Required prop `#{name}` was not specified"
          end
        end

        def validate_undefined(props)
          (props.keys - rules.keys).each do |prop_name|
            errors <<  "Provided prop `#{prop_name}` not specified in spec"
          end
        end

        def validate_value_array(name, value)
          klass = rules[name][:type]
          allow_nil = !!rules[name][:allow_nil]
          value.each_with_index do |item, index|
            type_check("`#{name}`[#{index}]", Native(item), klass[0], allow_nil)
          end
        rescue NoMethodError
          errors << "Provided prop `#{name}` was not an Array"
        end

        def coerce_native_hash_values(hash)
          hash.each do |key, value|
            hash[key] = Native(value)
          end
        end
      end
    end
  end
end
