RSpec.configure do |config|

  config.before(:each) do
    on_client do

      class App < React::Component::Base

        param optional_param: nil


        def render

          div do
            if children.count > 0
              children.each { |child| div { child.render } }
            elsif params.optional_param
              params.optional_param
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

        param optional_param: nil

        def render
          if params.optional_param
            params.optional_param
          else
            "Child1 got routed"
          end
        end
      end

      class Child2 < React::Component::Base
        param optional_param: nil

        def render
          if params.optional_param
            params.optional_param
          else
            "Child2 got routed"
          end
        end
      end

      class Child3 < React::Component::Base
        def render
          "Child3 got routed"
        end
      end

      class NativeTestRouter < React::Component::Base

        def render
          React::Router::Native::Router(routes: ROUTES.to_n)
        end

      end

      class TestRouter < React::Router

        class << self
          attr_accessor :promise
        end

      end


    end
  end
end
