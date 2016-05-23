require 'spec_helper'
require 'reactive_router/test_components'

describe "ReactiveRouter", js: true do

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
