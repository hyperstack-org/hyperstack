RSpec.configure do |config|

  config.before(:each) do
    on_client do

      class App < React::Component::Base
        def render
          div do
            if children.count > 0
              children.each { |child| div { child.render } }
            else
              "Rendering App: No Children"
            end
          end
        end
      end

      class Index < React::Component::Base
        def render
          "Index got routed"
        end
      end

      class Child1 < React::Component::Base
        def render
          "Child1 got routed"
        end
      end

      class Child2 < React::Component::Base
        def render
          "Child2 got routed"
        end
      end

      class Child3 < React::Component::Base
        def render
          "Child3 got routed"
        end
      end

      class NativeTestRouter < React::Component::Base

        def render
          React::RR::Router(routes: ROUTES.to_n)
        end

      end

    end
  end
end
