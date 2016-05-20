require 'spec_helper'
require 'reactive_router/test_components'

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
end
