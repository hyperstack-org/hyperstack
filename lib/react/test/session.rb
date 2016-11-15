module React
  module Test
    class Session
      DSL_METHODS = %i[mount instance native update_params html].freeze

      attr_reader :native

      def mount(component_klass, params = {})
        @element = React.create_element(component_klass, params)
        instance
      end

      def instance
        unless @instance
          @native = `React.addons.TestUtils.renderIntoDocument(#{@element.to_n})`
          @instance = `#@native._getOpalInstance()`
        end
        @instance
      end

      def update_params(params)
        cloned_element = React::Element.new(`React.cloneElement(#{@element.to_n}, #{params.to_n})`)
        prev_container = `#{@instance.dom_node}.parentNode`
        React.render(cloned_element, prev_container)
        nil
      end

      def html
        html = `#{@instance.dom_node}.parentNode.innerHTML`
        %x{
            var REGEX_REMOVE_ROOT_IDS = /\s?data-reactroot="[^"]*"/g;
            var REGEX_REMOVE_IDS = /\s?data-reactid="[^"]+"/g;
            html = html.replace(REGEX_REMOVE_ROOT_IDS, '');
            html = html.replace(REGEX_REMOVE_IDS, '');
        }
        return html
      end
    end
  end
end
