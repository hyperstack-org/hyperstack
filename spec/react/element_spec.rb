require "spec_helper"

describe 'React::Element', js: true do
  it 'bridges `type` of native React.Element attributes' do
    expect_evaluate_ruby do
      element = React.create_element('div')
      element.element_type
    end.to eq("div")
  end

  xit 'is renderable' do
    # dont know how to handle run_async
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
      client_option render_on: :both
      mount 'Foo' do
        class Foo
          include React::Component
          def render
            INPUT(value: nil, type: 'text').on(:change) {}
          end
        end
      end
      expect(page.body[-80..-19]).to match(/<input (type="text" value=""|value="" type="text").*\/>/)
    end
  end

  describe 'Component Event Subscription' do

    it 'will subscribe to a component event param' do
      evaluate_ruby do
        class Foo < React::Component::Base
          param :on_event, type: Proc, default: nil, allow_nil: true
          def render
            params.on_event
          end
        end
        React::Test::Utils.render_into_document(React.create_element(Foo).on(:event) {'works!'})
      end
      expect(page.body[-40..-19]).to include('<span>works!</span>')
    end

    it 'will subscribe to multiple component event params' do
      evaluate_ruby do
        class Foo < React::Component::Base
          param :on_event1, type: Proc, default: nil, allow_nil: true
          param :on_event2, type: Proc, default: nil, allow_nil: true
          def render
            params.on_event1+params.on_event2
          end
        end
        React::Test::Utils.render_into_document(React.create_element(Foo).on(:event1, :event2) {'works!'})
      end
      expect(page.body[-60..-19]).to include('<span>works!works!</span>')
    end

    it 'will subscribe to a native components event param' do
      evaluate_ruby do
        "make sure everything is loaded"
      end
      page.execute_script('window.NativeComponent = class extends React.Component {
        constructor(props) {
          super(props);
          this.displayName = "HelloMessage";
        }
        render() { return React.createElement("span", null, this.props.onEvent()); }
      }')
      evaluate_ruby do
        class Foo < React::Component::Base
          imports "NativeComponent"
        end
        React::Test::Utils.render_into_document(React.create_element(Foo).on(:event) {'works!'})
        true
      end
      expect(page.body[-60..-19]).to include('<span>works!</span>')
    end

    it 'will subscribe to a component event param with a non-default name' do
      evaluate_ruby do
        class Foo < React::Component::Base
          param :my_event, type: Proc, default: nil, allow_nil: true
          def render
            params.my_event
          end
        end
        React::Test::Utils.render_into_document(React.create_element(Foo).on("<my_event>") {'works!'})
      end
      expect(page.body[-60..-19]).to include('<span>works!</span>')
    end

    xit 'will subscribe to a component event param using the deprecated naming convention and generate a message' do
      evaluate_ruby do
        class Foo < React::Component::Base
          param :_onEvent, type: Proc, default: nil, allow_nil: true
          def render
            params._onEvent
          end
        end
        React::Test::Utils.render_into_document(React.create_element(Foo).on(:event) {'works!'})
      end
      expect(page.body[-60..-19]).to include('<span>works!</span>')
      expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
          .to match(/Warning: Failed prop( type|Type): In component `Foo`\nProvided prop `on_event` not specified in spec/)
      expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
         .to match(/In future releases React::Element#on('event') will no longer respond to the '_onEvent' emitter.\nRename your emitter param to 'on_event' or use .on('<_onEvent>')/)
      end
  end

  describe 'Builtin Event subscription' do
    xit 'is subscribable through `on(:event_name)` method' do
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
      expect_evaluate_ruby do
      element = React.create_element("div")
      element.on(:click){} == element
      end.to be_truthy
    end
  end
end
