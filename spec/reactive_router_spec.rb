require 'spec_helper'

describe "ReactiveRouter", js: true do

  before(:each) do
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

      class NativeTestRouter < React::Component::Base

        def render
          React::RR::Router(routes: ROUTES.to_n)
        end

      end

    end
  end

  it "has imported the Router component" do

    mount "NativeTestRouter" do

      ROUTES = [
        {path: '/', component: React::API::create_native_react_class(App)},
        {path: '/child1', component: React::API::create_native_react_class(Child1)}
      ]

    end
    page.should have_content("Rendering App: No Children")
    page.evaluate_script("window.ReactRouter.hashHistory.push('child1')")
    page.should have_content("Child1 got routed")

  end

  it "can build a simple router" do

    mount "TestRouter" do

      class TestRouter < React::Router
        def routes
          route("/", mounts: App)
        end
      end

    end

    page.should have_content("Rendering App: No Children")

  end

  it "react-router will route children" do

    mount "NativeTestRouter" do

      ROUTES = [
        {
          path: '/',
          component: React::API::create_native_react_class(App),
          childRoutes: [
            {path: 'child1', component: React::API::create_native_react_class(Child1)},
            {path: 'child2', component: React::API::create_native_react_class(Child2)}
          ]
        }
      ]

    end

    page.should have_content("Rendering App: No Children")
    page.evaluate_script("window.ReactRouter.hashHistory.push('child1')")
    page.should have_content("Child1 got routed")
    page.evaluate_script("window.ReactRouter.hashHistory.push('child2')")
    page.should have_content("Child2 got routed")

  end

  it "reactive-router will route children" do

    mount "TestRouter" do

      class TestRouter < React::Router
        def routes
          route("/", mounts: App) do
            route("child1", mounts: Child1)
            route("child2", mounts: Child2)
          end
        end
      end

    end

    page.should have_content("Rendering App: No Children")
    page.evaluate_script("window.ReactRouter.hashHistory.push('child1')")
    page.should have_content("Child1 got routed")
    page.evaluate_script("window.ReactRouter.hashHistory.push('child2')")
    page.should have_content("Child2 got routed")

  end

  it "reactive-router will route to an index route" do

    mount "TestRouter" do

      class TestRouter < React::Router
        def routes
          route("/", mounts: App, index: Index) do
            route("child1", mounts: Child1)
            route("child2", mounts: Child2)
          end
        end
      end

    end

    page.should have_content("Index got routed")

  end

  it "the index route can be specified with the index child method" do

    mount "TestRouter" do

      class TestRouter < React::Router
        def routes
          route("/", mounts: App) do
            index(mounts: Index)
            route("child1", mounts: Child1)
            route("child2", mounts: Child2)
          end
        end
      end

    end

    page.should have_content("Index got routed")

  end

end
