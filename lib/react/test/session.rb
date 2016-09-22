module React
  module Test
    class Session
      DSL_METHODS = %i[mount instance native element update_params
        force_update! html].freeze

      def mount(component_klass, params = {})
        @element = React.create_element(component_klass, params)
        instance
      end

      def instance
        unless @instance
          @native = Native(`React.addons.TestUtils.renderIntoDocument(#{element.to_n})`)
          @instance = `#{@native.to_n}._getOpalInstance()`
        end
        @instance
      end

      def native
        @native
      end

      def element
        @element
      end

      def update_params(params)
        cloned_element = React::Element.new(`React.cloneElement(#{self.element.to_n}, #{params.to_n})`)
        prev_container = `#{self.instance.dom_node}.parentNode`
        React.render(cloned_element, prev_container)
        nil
      end

      def force_update!
        native.force_update!
      end

      def html
        # How can we get the current ReactElement w/o violating private APIs?
        elem = Native(native[:_reactInternalInstance][:_currentElement])
        React.render_to_static_markup(elem)
      end
    end
  end
end
