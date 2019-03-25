module Hyperstack
  class Hotloader
    module AddErrorBoundry
      def self.included(base)
        base.after_error do |*err|
          @err = Hyperstack::Internal::Component::RescueWrapper.after_error_args || err
          Hyperstack::Component.force_update!
        end
        base.define_method :render do
          @err ? parse_display_and_clear_error : top_level_render
        end
      end

      def parse_display_and_clear_error
        e = @err[0]
        component_stack = @err[1]['componentStack'].split("\n ")
        @err = nil
        display_error(e, component_stack)
      end

      def display_error(e, component_stack)
        DIV do
          DIV { "Uncaught error: #{e}" }
          component_stack.each do |line|
            DIV { line }
          end
        end
      end
    end
  end
end
