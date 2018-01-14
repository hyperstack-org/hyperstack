require 'spec_helper'

describe 'Refs callback', js: true do
  before do
    on_client do
      class Foo
        include React::Component
        def self.bar
          @@bar ||= 'club'
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
          @@bar = bars
        end

        def render
          React.create_element(Bar, ref: method(:my_bar=).to_proc)
        end
      end

      element = React.create_element(Foo)
      React::Test::Utils.render_into_document(element)
      Foo.bar.class.name
    end.to eq('Bar')
  end

  it "is invoked with the actual DOM node" do
    # client_option raise_on_js_errors: :off
    expect_evaluate_ruby do
      Foo.class_eval do
        def my_div=(div)
          @@bar = div
        end

        def render
          React.create_element('div', ref: method(:my_div=).to_proc)
        end
      end

      element = React.create_element(Foo)
      React::Test::Utils.render_into_document(element)
      Foo.bar.JS['nodeType']
    end.to eq(1)
  end
end
