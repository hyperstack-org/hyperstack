module Hyperstack
  module Internal
    module Component
      module Rails
        class ComponentMount < React::Rails::ComponentMount
          attr_accessor :controller

          def setup(controller)
            self.controller = controller
          end

          def react_component(name, props = {}, options = {}, &block)
            if options[:prerender] || [:on, 'on', true].include?(Hyperstack.prerendering)
              options = context_initializer_options(options, name)
            end
            props = serialized_props(props, name, controller)
            result = super(top_level_name, props, options, &block).gsub("\n","")
            result = result.gsub(/(<script.*<\/script>)<\/div>$/,'</div>\1').html_safe
            result + footers
          end

          private

          def context_initializer_options(options, name)
            options[:prerender] = {options[:prerender] => true} unless options[:prerender].is_a? Hash
            existing_context_initializer = options[:prerender][:context_initializer]

            options[:prerender][:context_initializer] = lambda do |ctx|
              Hyperstack::Component::IsomorphicHelpers.load_context(ctx, controller, name)
              existing_context_initializer.call(ctx) if existing_context_initializer
            end

            options
          end

          def serialized_props(props, name, controller)
            { render_params: props, component_name: name,
              controller: controller.class.name.gsub(/Controller$/,"") }.react_serializer
          end

          def top_level_name
            'Hyperstack.Internal.Component.TopLevelRailsComponent'
          end

          def footers
            Hyperstack::Component::IsomorphicHelpers.prerender_footers(controller)
          end
        end
      end
    end
  end
end


module React
  module Rails
    module ViewHelper
      alias mount_component react_component
    end
  end
end
