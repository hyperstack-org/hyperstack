module React
  module Test
    class Utils
      `var ReactTestUtils = React.addons.TestUtils`

      def self.render_into_document(element, options = {})
        raise "You should pass a valid React::Element" unless React.is_valid_element(element)
        native_instance = `ReactTestUtils.renderIntoDocument(#{element.to_n})`

        if `#{native_instance}._getOpalInstance !== undefined`
          `#{native_instance}._getOpalInstance()`
        else
          native_instance
        end
      end

      def self.simulate(event, element)
        Simulate.new.click(element)
      end

      class Simulate
        include Native
        def initialize
          super(`ReactTestUtils.Simulate`)
        end

        def click(component_instance)
          `#{@native}['click']`.call(component_instance.dom_node, {})
        end
      end
    end
  end
end
