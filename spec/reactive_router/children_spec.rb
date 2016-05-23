require 'spec_helper'
require 'reactive_router/test_components'

describe "Creating Children Dynamically: The DSL can", js: true do

  it "compose children syncronously with a block" do

    mount "TestRouter" do
      class TestRouter < React::Router
        def routes
          route("/", mounts: App) do |ct|
            if ct.location[:query][:id] == "1"
              route("child", mounts: Child1)
            else
              route("child", mounts: Child2)
            end
          end
        end
      end
    end

    page.should have_content("Rendering App: No Children")
    page.evaluate_script("window.ReactRouter.hashHistory.push({pathname: 'child', query: {id: 1}})")
    page.should have_content("Child1 got routed")
    page.evaluate_script("window.ReactRouter.hashHistory.push({pathname: 'child', query: {id: 2}})")
    page.should have_content("Child2 got routed")

  end

  it "compose children asyncronously" do

    mount "TestRouter" do
      class TestRouter < React::Router

        def routes
          route("/", mounts: App) do |ct|
            TestRouter.promise = ct.promise.then_build_routes do |to|
              if to == 1
                route("child", mounts: Child1)
              else
                route("child", mounts: Child2)
              end
            end
          end
        end
      end
    end
    page.should have_content("Rendering App: No Children")
    page.evaluate_script("window.ReactRouter.hashHistory.push({pathname: 'child'})")
    page.should_not have_content("got routed", wait: 1)
    run_on_client { TestRouter.promise.resolve(2) }
    page.should have_content("Child2 got routed")
    page.evaluate_script("window.ReactRouter.hashHistory.push({pathname: 'child'})")
    run_on_client { TestRouter.promise.resolve(1) }
    page.should have_content("Child1 got routed")

  end

end
