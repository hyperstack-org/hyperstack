require 'spec_helper'
require 'reactrb_router/test_components'

describe "specifying the component to mount with a call back", js: true do

  it "by providing a lambda" do

    mount "TestRouter" do
      class TestRouter < React::Router
        def routes
          route("/", mounts: -> (ct) { App if ct.next_state[:location][:pathname] == "/" })
        end
      end
    end

    page.should have_content("Rendering App: No Children")

  end

  it "by using the mount hook" do

    mount "TestRouter" do
      class TestRouter < React::Router
        def routes
          route("/").mounts { |ct| App if ct.next_state[:location][:pathname] == "/" }
        end
      end
    end

    page.should have_content("Rendering App: No Children")

  end

  it "by using the mount hook that returns a promise" do

    mount "TestRouter" do
      class TestRouter < React::Router
        def routes
          route("/").mounts { TestRouter.promise = Promise.new.then { App }  }
        end
      end
    end

    page.should_not have_content("Rendering App: No Children", wait: 1)
    run_on_client { TestRouter.promise.resolve }
    page.should have_content("Rendering App: No Children")

  end

end
