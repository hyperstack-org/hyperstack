module React
  module Test
    class Session
      DSL_METHODS = %i[mount instance update_params html].freeze

      def mount(component_klass, params = {})
        @element = React.create_element(component_klass, params)
        instance
      end

      def instance
        unless @instance
          @container = `document.createElement('div')`
          @instance = React.render(@element, @container)
        end
        @instance
      end

      def update_params(params, &block)
        cloned_element = React::Element.new(`React.cloneElement(#{@element.to_n}, #{params.to_n})`)
        React.render(cloned_element, @container, &block)
        nil
      end

      def html
        html = `#@container.innerHTML`
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
