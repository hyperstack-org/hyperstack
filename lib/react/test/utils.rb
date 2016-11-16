module React
  module Test
    class Utils
      `var ReactTestUtils = React.addons.TestUtils`

      def self.render_into_document(element, options = {})
        raise "You should pass a valid React::Element" unless React.is_valid_element?(element)
        native_instance = `ReactTestUtils.renderIntoDocument(#{element.to_n})`

        if `#{native_instance}._getOpalInstance !== undefined`
          `#{native_instance}._getOpalInstance()`
        elsif `ReactTestUtils.isDOMComponent(#{native_instance}) && React.findDOMNode !== undefined`
          `React.findDOMNode(#{native_instance})`
        else
          native_instance
        end
      end

      def self.simulate(event, element, params = {})
        simulator = Native(`ReactTestUtils.Simulate`)
        simulator[event.to_s].call(`element.$dom_node === undefined` ? element : element.dom_node, params)
      end
    end
  end
end
