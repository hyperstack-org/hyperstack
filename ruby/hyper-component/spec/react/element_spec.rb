require "spec_helper"

describe 'React::Element', js: true do
  it 'bridges `type` of native React.Element attributes' do
    expect_evaluate_ruby do
      element = React.create_element('div')
      element.element_type
    end.to eq("div")
  end

  it 'is renderable' do
    expect_evaluate_ruby do
      element = React.create_element('span')
      div = JS.call(:eval, 'document.createElement("div")')
      React.render(element, div)
      div.JS[:children].JS[0].JS[:tagName]
    end.to eq("SPAN")
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
      expect(page.body[-285..-233]).to match(/<input (type="text" value=""|value="" type="text").*\/>/)
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
      expect(page.body[-50..-19]).to include('<span>works!</span>')
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
        "this makes sure everything is loaded"
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
  end

  describe 'Builtin Event subscription' do
    it 'is subscribable through `on(:event_name)` method' do
      expect_evaluate_ruby do
        element = React.create_element("div").on(:click) { |event| RESULT_C = 'clicked' if event.is_a? React::Event }
        dom_node = React::Test::Utils.render_into_document(element)
        React::Test::Utils.simulate_click(dom_node)
        RESULT_C rescue 'not clicked'
      end.to eq('clicked')

      expect_evaluate_ruby do
        element = React.create_element("div").on(:key_down) { |event| RESULT_P = 'pressed' if event.is_a? React::Event }
        dom_node = React::Test::Utils.render_into_document(element)
        React::Test::Utils.simulate_keydown(dom_node, "Enter")
        RESULT_P rescue 'not pressed'
      end.to eq('pressed')

      expect_evaluate_ruby do
        element = React.create_element("form").on(:submit) { |event| RESULT_S = 'submitted' if event.is_a? React::Event }
        dom_node = React::Test::Utils.render_into_document(element)
        React::Test::Utils.simulate_submit(dom_node)
        RESULT_S rescue 'not submitted'
      end.to eq('submitted')
    end

    it 'returns self for `on` method' do
      expect_evaluate_ruby do
        element = React.create_element("div")
        element.on(:click){} == element
      end.to be_truthy
    end
  end
end
