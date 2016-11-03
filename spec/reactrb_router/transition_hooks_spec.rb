require 'spec_helper'
require 'reactrb_router/test_components'

describe "transition hooks", js: true do
  it "reactrb-router will route children" do

    mount "TestRouter" do
      class TestRouter < React::Router
        def routes
          route("/", mounts: App) do
            route("child1", mounts: Child1)
            route("child2", mounts: Child2)
          end.on(:change) do
            # debugger
            # nil
          end
        end
      end
    end
    #binding.pry
    page.should have_content("Rendering App: No Children")
    page.evaluate_script("window.ReactRouter.hashHistory.push('child1')")
    page.should have_content("Child1 got routed")
    page.evaluate_script("window.ReactRouter.hashHistory.push('child2')")
    page.should have_content("Child2 got routed")
  end

  it "receive the prev and next state" do

    mount "TestRouter" do
      class TestRouter < React::Router

        param :on_route_change, type: Proc

        def routes
          route("/", mounts: App) do
            route("child1", mounts: Child1).
            on(:change) do |c|
              params.on_route_change(:child1, :change, :prev, c.prev_state[:location][:pathname])
              params.on_route_change(:child1, :change, :next, c.next_state[:location][:pathname])
            end.on(:enter) do |c|
              params.on_route_change(:child1, :enter, :next, c.next_state[:location][:pathname])
            end.on(:leave) do |c|
              params.on_route_change(:child1, :leave)
            end
            route("child2", mounts: Child2)
            route("child3", mounts: Child3)
          end.on(:change) do |c|
            c.replace("/child3") if c.next_state[:location][:pathname] == "/child2"
            params.on_route_change(:root, :change, :prev, c.prev_state[:location][:pathname])
            params.on_route_change(:root, :change, :next, c.next_state[:location][:pathname])
          end.on(:enter) do |c|
            c.replace("/child1") if c.next_state[:location][:pathname] == "/"
            params.on_route_change(:root, :enter, :next, c.next_state[:location][:pathname])
          end.on(:leave) do |c|
            params.on_route_change(:root, :leave)
          end
        end
      end
    end

    page.evaluate_script("window.ReactRouter.hashHistory.push('child2')")
    event_history_for("route_change").should eq([
      ["root", "enter", "next", "/"],
      # on(:enter) replaces "/" with "/child1"
      ["root", "enter", "next", "/child1"], ["child1", "enter", "next", "/child1"],
      # push('child2')
      ["child1", "leave"], ["root", "change", "prev", "/child1"], ["root", "change", "next", "/child2"],
      # on(:change) replaces "/child1" with "/child3"
      ["child1", "leave"], ["root", "change", "prev", "/child1"], ["root", "change", "next", "/child3"]
    ])
    page.should have_content("Child3 got routed")
  end

  it "can wait on a promise if a promise is returned from the event handler" do

    mount "TestRouter" do
      class TestRouter < React::Router

        def routes
          route("/", mounts: App) do
            route("child1", mounts: Child1)
          end.on(:change) do |c|
            self.class.promise = c.promise
          end.on(:enter) do |c|
            self.class.promise = c.promise
          end
        end
      end
    end

    page.should_not have_content("Rendering App: No Children", wait: 1)
    run_on_client { TestRouter::promise.resolve }
    page.should have_content("Rendering App: No Children")
    page.evaluate_script("window.ReactRouter.hashHistory.push('child1')")
    page.should_not have_content("Child1 got routed", wait: 1)
    run_on_client { TestRouter::promise.resolve }
    page.should have_content("Child1 got routed")

  end

  it "be defined as inline procs" do

    mount "TestRouter" do
      class TestRouter < React::Router

        param :on_route_change, type: Proc

        def routes
          route(
            "/",
            mounts: App,
            on_change: lambda do |c|
              params.on_route_change(:app, :change, :prev, c.prev_state[:location][:pathname])
              params.on_route_change(:app, :change, :next, c.next_state[:location][:pathname])
            end
            ) do
            route(
              "child1",
              mounts: Child1,
              on_enter: lambda do |c|
                params.on_route_change(:child1, :enter, :next, c.next_state[:location][:pathname])
              end,
              on_leave: lambda do |c|
                params.on_route_change(:child1, :leave)
              end
            )
            route("child2", mounts: Child2)
          end
        end
      end
    end

    page.evaluate_script("window.ReactRouter.hashHistory.push('child1')")
    page.evaluate_script("window.ReactRouter.hashHistory.push('child2')")
    event_history_for("route_change").should eq([
      ["app", "change", "prev", "/"], ["app", "change", "next", "/child1"], ["child1", "enter", "next", "/child1"], ["child1", "leave"],
      ["app", "change", "prev", "/child1"], ["app", "change", "next", "/child2"]])
    page.should have_content("Child2 got routed")
  end


end
