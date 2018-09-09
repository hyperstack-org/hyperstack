require "spec_helper"

describe 'React::Event', js: true do
  it "should bridge attributes of native SyntheticEvent (see http://facebook.github.io/react/docs/events.html#syntheticevent)" do
    expect_evaluate_ruby do
      results = {}
      element = React.create_element('div').on(:click) do |event|
        results[:bubbles] = event.bubbles == event.to_n.JS[:bubbles]
        results[:cancelable] = event.cancelable == event.to_n.JS[:cancelable]
        results[:current_target] = event.current_target == event.to_n.JS[:currentTarget]
        results[:default_prevented] = event.default_prevented == event.to_n.JS[:defaultPrevented]
        results[:event_phase] = event.event_phase == event.to_n.JS[:eventPhase]
        results[:is_trusted?] = event.is_trusted? == event.to_n.JS[:isTrusted]
        results[:native_event] = event.native_event == event.to_n.JS[:nativeEvent]
        results[:target] = event.target == event.to_n.JS[:target]
        results[:timestamp] = event.timestamp == event.to_n.JS[:timeStamp]
        results[:event_type] = event.event_type == event.to_n.JS[:type]
        results[:prevent_default] = event.respond_to?(:prevent_default)
        results[:stop_propagation] = event.respond_to?(:stop_propagation)
      end
      dom_node = React::Test::Utils.render_into_document(element)
      React::Test::Utils.simulate_click(dom_node)
      results
    end.to eq({
      'bubbles' => true,
      'cancelable' => true,
      'current_target' => true,
      'default_prevented' => true,
      'event_phase' => true,
      'is_trusted?' => true,
      'native_event' => true,
      'target' => true,
      'timestamp' => true,
      'event_type' => true,
      'prevent_default' => true,
      'stop_propagation' => true
    })
  end
end
