require 'spec_helper'
require 'reactive_router/test_components'

describe "ReactiveRouter::link", js: true do

  it "can render a clickable link" do

    mount "TestRouter" do

      class App < React::Component::Base
        def render
          div do
            div do
              [1..3].each { |i| div(style: {float: :left}) { link("/#{i}", id: "link-#{i}") { "Link-#{i}"}}}
            end
            children.first.render
          end
        end
      end

      class TestRouter < React::Router
        def routes
          route("/", mounts: App) do
            route(":id").mounts { |ctx| Object.const_get "Child#{ctx.params[:id]}" }
          end
        end
      end
    end

    page.should have_content("Rendering App: No Children")

  end
end
