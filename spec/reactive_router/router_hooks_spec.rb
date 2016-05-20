require 'spec_helper'
require 'reactive_router/test_components'

describe "router hooks", js: true do

  it "history" do

    mount "TestRouter" do
      class TestRouter < React::Router

        def history
          browser_history
        end

        def routes
          route("/react_test/:test_id", mounts: App)
        end
      end
    end

    page.should have_content("Rendering App: No Children")
  end
end
