module Hyperstack
  module Gate
    module ClassMethods
      def defined_policies
        @defined_policies ||= {}
      end

      def defined_qualifiers
        @defined_qualifiers ||= {}
      end

      def execute(&block)
        block.call
      end

      def policy_for(action_symbol, &block)
        @current_action = action_symbol

        defined_policies[action_symbol] = { qualifiers: {}, executors: [] }

        allow_method_name_sym = "allow_#{action_symbol}?".to_sym
        qualify_method_name_sym = "qualify_args_for_#{action_symbol}".to_sym
        verify_method_name_sym = "verify_args_for_#{action_symbol}".to_sym
        execute_method_name_sym = "execute_policy_for_#{action_symbol}".to_sym

        block.call

        define_method(qualify_method_name_sym) do |*policy_context|
          self.class.defined_policies[action_symbol][:qualifiers].each do |qualifier, _nil|
            qualifier_block = self.class.defined_qualifiers[qualifier]
            raise "No Qualifier block for #{qualifier} for #{action_symbol} in #{self.class}!" unless qualifier_block
            instance_variable_set("@_#{action_symbol}_#{qualifier}", instance_exec(*policy_context, &qualifier_block))
          end
        end

        define_method(verify_method_name_sym) do
          self.class.defined_policies[action_symbol][:qualifiers].keys.each do |qualifier|
            qualifier_val = instance_variable_get("@_#{action_symbol}_#{qualifier}")
            qualifier_val_class = qualifier_val.class
            unless qualifier_val_class == TrueClass || qualifier_val_class == FalseClass
              raise "Qualified value for #{qualifier} for #{action_symbol} must be of TrueClass or FalseClass, but is #{qualifier_val_class}!"
            end
          end
        end

        define_method(execute_method_name_sym) do
          result = { denied: "#{self.class}, #{action_symbol}: No rule matched!" }
          self.class.defined_policies[action_symbol][:executors].each do |executor|
            rule_result = true
            executor[:ruleset].each do |qualifier, expected_qualifier_value|
              value = instance_variable_get("@_#{action_symbol}_#{qualifier}")
              rule_result = rule_result && (expected_qualifier_value == value)
              break if rule_result != true
            end
            if rule_result == true
              expected_values = executor[:ruleset].each.map { |qualifier, value| { qualifier => value } }
              qualified_values = executor[:ruleset].keys.map { |qualifier| { qualifier => instance_variable_get("@_#{action_symbol}_#{qualifier}") } }
              if executor[:type] == :allow
                result = { allowed: { expected_values: expected_values, qualified_values: qualified_values }}
              elsif executor[:type] == :deny
                result = { denied: { expected_values: expected_values, qualified_values: qualified_values }}
              end
              break
            end
          end
          result
        end

        define_method(allow_method_name_sym) do |*policy_context|
          send(qualify_method_name_sym, *policy_context)
          send(verify_method_name_sym)
          send(execute_method_name_sym)
        end

        @current_action = nil
      end

      def qualify(qualifier_symbol, &block)
        raise "Qualifier #{qualifier_symbol} already defined!" if defined_qualifiers.has_key?(qualifier_symbol)
        defined_qualifiers[qualifier_symbol] = block
      end

      def Allow(condition_hash)
        text_rule = "#{self}, #{@current_action}: Allow #{condition_hash}"

        executor = { description: text_rule, type: :allow, ruleset: {} }
        condition_hash.each do |condition, qualifier|
          raise "Qualifier #{qualifier} not defined in #{self}!" unless defined_qualifiers.has_key?(qualifier)
          current_action_qualifiers[qualifier] = nil unless current_action_qualifiers.has_key?(qualifier)

          if executor[:ruleset].has_key?(qualifier)
            raise "Qualifier #{qualifier} specified more then once in rule for #{@current_action}: #{text_rule}!"
          end
          executor[:ruleset][qualifier] = case condition
                                        when :if, :and_if then true
                                        when :if_not, :and_if_not, :unless then false
                                        else
                                          raise "Unknown condition #{condition} in rule for #{@current_action}: #{text_rule} !"
                                        end
        end
        current_action_executors << executor
      end

      def Deny(condition_hash)
        text_rule = "#{self}, #{@current_action}: Deny #{condition_hash}"

        executor = { description: text_rule, type: :deny, ruleset: {} }
        condition_hash.each do |condition, qualifier|
          raise "Qualifier #{qualifier} not defined in #{self}!" unless defined_qualifiers.has_key?(qualifier)
          current_action_qualifiers[qualifier] = nil unless current_action_qualifiers.has_key?(qualifier)

          if executor[:ruleset].has_key?(qualifier)
            raise "Qualifier #{qualifier} specified more then once in rule for #{@current_action}: #{text_rule}!"
          end
          executor[:ruleset][qualifier] = case condition
                                        when :if, :and_if then true
                                        when :if_not, :and_if_not, :unless then false
                                        else
                                          raise "Unknown condition #{condition} in rule for #{@current_action}: #{text_rule}!"
                                        end
        end
        current_action_executors << executor
      end

      private

      def current_action_qualifiers
        defined_policies[@current_action][:qualifiers]
      end

      def current_action_executors
        defined_policies[@current_action][:executors]
      end
    end
  end
end