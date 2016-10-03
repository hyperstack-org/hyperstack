require 'spec_helper'

if opal?
describe 'React::State' do
  it "can created static exported states" do
    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component
      export_state(:foo) { 'bar' }
    end

    expect(Foo.foo).to eq('bar')
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
    stub_const 'StateTest', Class.new(React::Component::Base)
    StateTest.class_eval do
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
    %x{
      var log = [];
      var org_warn_console =  window.console.warn;
      var org_error_console = window.console.error;
      window.console.warn = window.console.error = function(str){log.push(str)}
    }
    markup = React.render_to_static_markup(React.create_element(StateTest))
    `window.console.warn = org_warn_console; window.console.error = org_error_console;`
    expect(markup).to eq('<span>Boom</span>')
    expect(StateTest.boom).to be_falsy
    expect(`log`).to eq([])
  end
end
end
