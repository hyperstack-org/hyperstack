module Hyperstack
  module Component
    module FreeRender
      def self.included(base)
        base.instance_eval do
          alias :hyperstack_component_original_meth_missing method_missing
          def method_missing(name, *args, &block)
            if const_defined?(name) &&
               (klass = const_get(name)) &&
               ((klass.is_a?(Class) && klass.method_defined?(:render)) ||
                 Hyperstack::Internal::Component::Tags::HTML_TAGS.include?(klass))
              render(klass, *args, &block)
            else
              hyperstack_component_original_meth_missing(name, *args, &block)
            end
          end
        end
      end
    end
  end
end
