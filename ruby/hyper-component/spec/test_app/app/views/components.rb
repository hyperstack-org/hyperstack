require 'hyper-component'
if Hyperstack::Component::IsomorphicHelpers.on_opal_client?
  require 'browser'
  require 'browser/delay'
  #require 'react/ext/opal-jquery/element'
  require 'hyperstack/component/jquery'
end
require 'hyperstack/component/server'
require 'hyperstack/component/auto-import'
require 'js'
require 'hyper-store'
require 'hyperstack/internal/component/haml'

# these mechanisms are deprecated in favor of using the features of hyper-spec.  However
# in order to expedite getting Hyperstack 1.0 released we are just leaving these methods
# here until the specs get cleaned up
module Hyperstack
  module Component
    module ReactTestUtils
      def self.render_component_into_document(component, args = {})
        element = Hyperstack::Component::ReactAPI.create_element(component, args)
        render_into_document(element)
      end

      def self.render_into_document(element)
        raise "You should pass a valid Hyperstack::Component::Element" unless Hyperstack::Component::ReactAPI.is_valid_element?(element)
        dom_el = `document.body.querySelector('div[data-react-class="Hyperstack.Internal.Component.TopLevelRailsComponent"]').appendChild(document.createElement('div'))`
        Hyperstack::Component::ReactAPI.render(element, dom_el)
      end

      def self.simulate_click(element)
        # element must be a component or a dom node or a element
        el =  if `typeof element.nodeType !== "undefined"`
                element
              elsif element.respond_to? :dom_node
                element.dom_node
              elsif element.is_a? Hyperstack::Component::Element
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
        element
      end

      def self.simulate_keydown(element, key_name = "Enter")
        # element must be a component or a dom node or a element
        el =  if `typeof element.nodeType !== "undefined"`
                element
              elsif element.respond_to? :dom_node
                element.dom_node
              elsif element.is_a? Hyperstack::Component::Element
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
              elsif element.respond_to? :dom_node
                element.dom_node
              elsif element.is_a? Hyperstack::Component::Element
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


require_tree './components'
