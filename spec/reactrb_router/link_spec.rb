require 'spec_helper'
require 'reactrb_router/test_components'

describe "ReactrbRouter::link", js: true do

  it "can render a clickable link" do

    mount "TestRouter" do

      ComponentHelpers::add_class(:active, color: :red, border: "thin solid")

      class App < React::Component::Base
        def render
          div do
            TestRouter::Link("/", id: "link-4", only_active_on_index: true, active_style: {border: "thin solid", color: :red}) { "Home"}
            (1..3).each { |i| div(style: {float: :left, "margin-right" => 20}) { TestRouter::Link("/#{i}", id: "link-#{i}", active_class: :active) { "Link-#{i}"}}}
            div(style: {clear: :both}) { children.first.render } unless children.count == 0
          end
        end
      end

      class TestRouter < React::Router
        def routes
          route("/", mounts: App) do
            route(":id").mounts do |ctx|
              Object.const_get "Child#{ctx.next_state[:params][:id]}"
            end
          end
        end
      end
    end

    page.should_not have_content("got routed", wait: 1)

    (1..3).each do |i|
      page.find("#link-#{i}").click
      page.should have_content("Child#{i} got routed")
      page.find("#link-#{i}.active")
      page.find("#link-4").native.css_value('border').should_not eq("thin solid")
    end
    page.find("#link-4").click
    page.find("#link-4").native.css_value('border').should eq("thin solid")
    page.should_not have_content("got routed", wait: 1)
  end
end
