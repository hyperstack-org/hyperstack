require 'spec_helper'
require 'reactive_router/test_components'

# Test assumptions on how react-router api works, and how it interfaces into react.rb

describe "react-router native api", js: true do

  it "has imported the Router component" do

    mount "NativeTestRouter" do
      ROUTES = [
        {path: '/', component: React::API::create_native_react_class(App)},
        {path: '/child1', component: React::API::create_native_react_class(Child1)}
      ]
    end
    binding.pry
    page.should have_content("Rendering App: No Children")
    page.evaluate_script("window.ReactRouter.hashHistory.push('child1')")
    page.should have_content("Child1 got routed")

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

  it "react-router will dynamically route children" do

    mount "NativeTestRouter" do
      ROUTES = [
        {
          path: '/',
          component: React::API::create_native_react_class(App),
          getChildRoutes: lambda do |location, callBack|
            routes = [
              {path: 'child1', component: React::API::create_native_react_class(Child1)},
              {path: 'child2', component: React::API::create_native_react_class(Child2)}
            ].to_n
            callBack.call(nil.to_n, routes)
          end.to_n
        }
      ]
    end

    page.should have_content("Rendering App: No Children")
    page.evaluate_script("window.ReactRouter.hashHistory.push('child1')")
    page.should have_content("Child1 got routed")
    page.evaluate_script("window.ReactRouter.hashHistory.push('child2')")
    page.should have_content("Child2 got routed")

  end

  it "passes params to child routes" do

    mount "NativeTestRouter" do

      ROUTES = [
        {path: '/', component: React::API::create_native_react_class(App)},
        {path: '/child1', component: React::API::create_native_react_class(ParamChild), param1: :bar}
      ]

    end
    page.evaluate_script("window.ReactRouter.hashHistory.push('child1')")
    page.should have_content("param1 = bar")

  end
end
