require 'spec_helper'

describe 'React::State', js: true do
  it "can create dynamically initialized exported states" do
    expect_evaluate_ruby do
      class Foo
        include React::Component
        export_state(:foo) { 'bar' }
      end
      Hyperloop::Application::Boot.run
      Foo.foo
    end.to eq('bar')
  end

  # these will all require async operations and testing to see if things get
  # re-rendered see spec_helper the "render" test method

  # if Foo.foo is used during rendering then when Foo.foo changes we will
  # rerender
  it "sets up observers when exported states are read"

  # React::State.set_state(object, attribute, value) +
  # React::State.get_state(object, attribute)
  it "can be accessed outside of react using get/set_state"

  it 'ignores state updates during rendering' do
    client_option render_on: :both    
    evaluate_ruby do
      class StateTest < React::Component::Base
        export_state :boom
        before_mount do
          # force boom to be on the observing list during the current rendering cycle
          StateTest.boom! !StateTest.boom
          # this is automatically called by after_mount / after_update, but we don't want
          # to have to setup a complicated async test, so we just force it now.
          # if we don't do this, then updating boom will have no effect on the first render
          React::State.update_states_to_observe
        end
        def render
          (StateTest.boom ? "Boom" : "No Boom").tap { StateTest.boom! !StateTest.boom }
        end
      end
      MARKUP = React::Server.render_to_static_markup(React.create_element(StateTest))
    end
    expect_evaluate_ruby("MARKUP").to eq('<span>Boom</span>')
    expect_evaluate_ruby("StateTest.boom").to be_falsy
    expect(page.driver.browser.manage.logs.get(:browser).reject { |entry|
      entry_s = entry.to_s
      entry_s.include?("Deprecated feature") || entry_s.include?("Mount() on the server. This is a no-op.")
    }.size).to eq(0)
  end
end
