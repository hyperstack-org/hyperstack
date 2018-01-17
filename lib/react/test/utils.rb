module React
  module Test
    class Utils
      def self.render_component_into_document(component, args = {})
        element = React.create_element(component, args)
        render_into_document(element)
      end

      def self.render_into_document(element)
        raise "You should pass a valid React::Element" unless React.is_valid_element?(element)
        dom_el = `document.body.querySelector('div[data-react-class="React.TopLevelRailsComponent"]').appendChild(document.createElement('div'))`
        React.render(element, dom_el)
      end

      def self.simulate_click(element)
        # element must be a component or a dom node or a element
        el =  if `typeof element.nodeType !== "undefined"`
                element
              elsif element.is_a? React::Component
                element.dom_node
              elsif element.is_a? React::Element
                `ReactDOM.findDOMNode(#{element.to_n}.native)`
              else
                element
              end
        %x{
          var evob = new MouseEvent('click', {
            view: window,
            bubbles: true,
            cancelable: true
          });
          el.dispatchEvent(evob);
        }
      end

      def self.simulate_keydown(element, key_name = "Enter")
        # element must be a component or a dom node or a element
        el =  if `typeof element.nodeType !== "undefined"`
                element
              elsif element.is_a? React::Component
                element.dom_node
              elsif element.is_a? React::Element
                `ReactDOM.findDOMNode(#{element.to_n}.native)`
              else
                element
              end
        %x{
          var evob = new KeyboardEvent('keydown', { key: key_name, bubbles: true, cancelable: true });
          el.dispatchEvent(evob);
        }
      end

      def self.simulate_submit(element)
        # element must be a component or a dom node or a element
        el =  if `typeof element.nodeType !== "undefined"`
                element
              elsif element.is_a? React::Component
                element.dom_node
              elsif element.is_a? React::Element
                `ReactDOM.findDOMNode(#{element.to_n}.native)`
              else
                element
              end
        %x{
          var evob = new Event('submit', { bubbles: true, cancelable: true });
          el.dispatchEvent(evob);
        }
      end
    end
  end
end
