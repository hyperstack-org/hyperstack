module React
  module Test
    module Matchers
      class RenderHTMLMatcher
        def initialize(expected)
          @expected = expected
          @params = {}
        end

        def with_params(params)
          @params = params
          self
        end

        def matches?(component)
          @component = component
          @actual = render_to_html
          @expected == @actual
        end

        def failure_message
          failure_string
        end

        def failure_message_when_negated
          failure_string(:negative)
        end

        alias negative_failure_message failure_message_when_negated

        private

        def render_to_html
          element = React.create_element(@component, @params)
          React::Server.render_to_static_markup(element)
        end

        def failure_string(negative = false)
          str = "expected '#{@component.name}' with params '#{@params}' to "
          str = str + "not " if negative
          str = str + "render '#{@expected}', but '#{@actual}' was rendered."
          str
        end
      end

      def render_static_html(*args)
        RenderHTMLMatcher.new(*args)
      end

      def render(*args)
        %x{ console.error("Warning: `render` matcher is deprecated in favor of `render_static_html`."); }
        RenderHTMLMatcher.new(*args)
      end
    end
  end
end
