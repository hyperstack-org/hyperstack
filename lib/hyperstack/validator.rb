module Hyperstack
  class Validator
    attr_accessor :errors
    attr_accessor :allow_undefined_props
    attr_reader :props_wrapper
    private :errors #, :props_wrapper

    def initialize
      @props_wrapper = Class.new(Hyperstack::PropsWrapper)
    end

    def self.build(&block)
      self.new.build(&block)
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

    def undefined_props(props)
      self.allow_undefined_props = true
      props.reject { |name, _value| rules[name] }
    end

    def validate(props)
      self.errors = []
      validate_undefined(props) unless allow_undefined_props
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
        .select {|_key, value| value.keys.include?(:default) }
        .inject({}) {|memo, (k,v)| memo[k] = v[:default]; memo}
    end

    private

    def defined_props(props)
      props.select { |name| rules.keys.include?(name) }
    end

    def rules
      if RUBY_ENGINE == 'opal'
        @rules ||= { children: { required: false }, className: { required: false } } # thats for components
      else
        @rules ||= {}
      end
    end

    def define_rule(name, options = {})
      rules[name] = coerce_native_hash_values(options)
      props_wrapper.define_param(name, options[:type])
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
      return unless props.any?
      (props.keys - rules.keys).each do |prop_name|
        errors <<  "Provided prop `#{prop_name}` not specified in spec"
      end
    end

    def validate_value_array(name, value)
      klass = rules[name][:type]
      allow_nil = !!rules[name][:allow_nil]
      value.each_with_index do |item, index|
        if RUBY_ENGINE == 'opal'
          type_check("`#{name}`[#{index}]", Native(item), klass[0], allow_nil)
        else
          type_check("`#{name}`[#{index}]", item, klass[0], allow_nil)
        end
      end
    rescue NoMethodError
      errors << "Provided prop `#{name}` was not an Array"
    end

    def coerce_native_hash_values(hash)
      hash.each do |key, value|
        if RUBY_ENGINE == 'opal'
          hash[key] = Native(value)
        else
          hash[key] = value
        end
      end
    end
  end
end
