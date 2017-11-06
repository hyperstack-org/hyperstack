require "spec_helper"

if opal?
# require 'reactrb/new-event-name-convention' # this require will get rid of any error messages but
# the on method will no longer attach to the param prefixed with _on
describe React::Element, type: :component do
  it 'bridges `type` of native React.Element attributes' do
    element = React.create_element('div')
    expect(element.element_type).to eq("div")
  end

  async 'is renderable' do
    element = React.create_element('span')
    div = `document.createElement("div")`
    React.render(element, div) do
      run_async {
        expect(`div.children[0].tagName`).to eq("SPAN")
      }
    end
  end

  describe "Event Subscription" do
    it "keeps the original params" do
      stub_const 'Foo', Class.new
      Foo.class_eval do
        include React::Component
        def render
          INPUT(value: nil, type: 'text').on(:change) {}
        end
      end

      expect(React::Server.render_to_static_markup(React.create_element(Foo))).to match(/<input (type="text" value=""|value="" type="text")(\/)?>/)
    end
  end

  describe 'Component Event Subscription' do

    it 'will subscribe to a component event param' do
      stub_const 'Foo', Class.new(React::Component::Base)
      Foo.class_eval do
        param :on_event, type: Proc, default: nil, allow_nil: true
        def render
          params.on_event
        end
      end
      expect(React::Server.render_to_static_markup(React.create_element(Foo).on(:event) {'works!'})).to eq('<span>works!</span>')
    end

    it 'will subscribe to multiple component event params' do
      stub_const 'Foo', Class.new(React::Component::Base)
      Foo.class_eval do
        param :on_event1, type: Proc, default: nil, allow_nil: true
        param :on_event2, type: Proc, default: nil, allow_nil: true
        def render
          params.on_event1+params.on_event2
        end
      end
      expect(React::Server.render_to_static_markup(React.create_element(Foo).on(:event1, :event2) {'works!'})).to eq('<span>works!works!</span>')
    end

    it 'will subscribe to a native components event param' do
      %x{
        window.NativeComponent = class extends React.Component({
          displayName: "HelloMessage",
          render() {
            return React.createElement("span", null, this.props.onEvent());
          }
        })
      }
      stub_const 'Foo', Class.new(React::Component::Base)
      Foo.class_eval do
        imports "NativeComponent"
      end
      expect(React::Server.render_to_static_markup(React.create_element(Foo).on(:event) {'works!'})).to eq('<span>works!</span>')
    end

    it 'will subscribe to a component event param with a non-default name' do
      stub_const 'Foo', Class.new(React::Component::Base)
      Foo.class_eval do
        param :my_event, type: Proc, default: nil, allow_nil: true
        def render
          params.my_event
        end
      end
      expect(React::Server.render_to_static_markup(React.create_element(Foo).on("<my_event>") {'works!'})).to eq('<span>works!</span>')
    end

    it 'will subscribe to a component event param using the deprecated naming convention and generate a message' do
      stub_const 'Foo', Class.new(React::Component::Base)
      Foo.class_eval do
        param :_onEvent, type: Proc, default: nil, allow_nil: true
        def render
          params._onEvent
        end
      end
      %x{
        var log = [];
        var org_warn_console =  window.console.warn;
        var org_error_console = window.console.error;
        window.console.warn = window.console.error = function(str){log.push(str)}
      }
      expect(React::Server.render_to_static_markup(React.create_element(Foo).on(:event) {'works!'})).to eq('<span>works!</span>')
      `window.console.warn = org_warn_console; window.console.error = org_error_console;`
      expect(`log[0]`).to match(/Warning: Failed prop( type|Type): In component `Foo`\nProvided prop `on_event` not specified in spec/)
      expect(`log[1]`).to eq("Warning: Deprecated feature used in Foo. In future releases React::Element#on('event') will no longer respond to the '_onEvent' emitter.\nRename your emitter param to 'on_event' or use .on('<_onEvent>')")
    end
  end

  describe 'Builtin Event subscription' do
    it 'is subscribable through `on(:event_name)` method' do
      expect { |b|
        element = React.create_element("div").on(:click, &b)
        dom_node = React::Test::Utils.render_into_document(element)
        React::Test::Utils.simulate(:click, dom_node)
      }.to yield_with_args(React::Event)

      expect { |b|
        element = React.create_element("div").on(:key_down, &b)
        dom_node = React::Test::Utils.render_into_document(element)
        React::Test::Utils.simulate(:keyDown, dom_node, {key: "Enter"})
      }.to yield_control

      expect { |b|
        element = React.create_element("form").on(:submit, &b)
        dom_node = React::Test::Utils.render_into_document(element)
        React::Test::Utils.simulate(:submit, dom_node)
      }.to yield_control
    end

    it 'returns self for `on` method' do
      element = React.create_element("div")
      expect(element.on(:click){}).to eq(element)
    end
  end
end
end
