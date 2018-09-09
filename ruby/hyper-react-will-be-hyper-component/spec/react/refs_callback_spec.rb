require 'spec_helper'

describe 'Refs callback', js: true do
  before do
    on_client do
      class Foo
        include React::Component
        def self.bar
          @@bar
        end
        def self.bar=(club)
          @@bar = club
        end
      end
    end
  end

  it "is invoked with the actual Ruby instance" do
    expect_evaluate_ruby do
      class Bar
        include React::Component
        def render
          React.create_element('div')
        end
      end

      Foo.class_eval do
        def my_bar=(bars)
          Foo.bar = bars
        end

        def render
          React.create_element(Bar, ref: method(:my_bar=).to_proc)
        end
      end

      element = React.create_element(Foo)
      React::Test::Utils.render_into_document(element)
      begin
        "#{Foo.bar.class.name}"
      rescue
        "Club"
      end
    end.to eq('Bar')
  end

  it "is invoked with the actual DOM node" do
    # client_option raise_on_js_errors: :off
    expect_evaluate_ruby do
      Foo.class_eval do
        def my_div=(div)
          Foo.bar = div
        end

        def render
          React.create_element('div', ref: method(:my_div=).to_proc)
        end
      end

      element = React.create_element(Foo)
      React::Test::Utils.render_into_document(element)
      "#{Foo.bar.JS['nodeType']}" # avoids json serialisation errors by using "#{}"
    end.to eq("1")
  end

  it "works, even when the component is unmounted" do
    # was a bug, on unmount react calls the ref method with null instead of a dom node
    # callback failed then
    # ref is called two times, once on mount with dom_node, once on unmount with null
    mount "Foo" do
      class Unmountable < Hyperloop::Component
        render do
          DIV { "This is a Component" }
        end
      end
      Foo.class_eval do
        def ref_rec(dom_node)
          @@rec_cnt ||= 0
          @@rec_cnt += 1
        end
        def self.rec_cnt
          @@rec_cnt
        end

        after_mount { mutate.unmount true }

        render do
          Unmountable(ref: method(:ref_rec).to_proc) unless state.unmount 
        end
      end
    end
    expect_evaluate_ruby('Foo.rec_cnt').to eq(2)
  end
end
