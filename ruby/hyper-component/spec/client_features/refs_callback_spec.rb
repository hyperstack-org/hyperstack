require 'spec_helper'

describe 'Refs callback', js: true do
  before do
    on_client do
      class Foo
        include Hyperstack::Component
        include Hyperstack::State::Observable
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
        include Hyperstack::Component
        def render
          Hyperstack::Component::ReactAPI.create_element('div')
        end
      end

      Foo.class_eval do
        def my_bar=(bars)
          Foo.bar = bars
        end

        def render
          Hyperstack::Component::ReactAPI.create_element(Bar, ref: method(:my_bar=).to_proc)
        end
      end

      element = Hyperstack::Component::ReactAPI.create_element(Foo)
      Hyperstack::Component::ReactTestUtils.render_into_document(element)
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
        def my_div=(a_div)
          Foo.bar = a_div
        end

        def render
          Hyperstack::Component::ReactAPI.create_element('div', ref: method(:my_div=).to_proc)
        end
      end

      element = Hyperstack::Component::ReactAPI.create_element(Foo)
      Hyperstack::Component::ReactTestUtils.render_into_document(element)
      "#{Foo.bar.JS['nodeType']}" # avoids json serialisation errors by using "#{}"
    end.to eq("1")
  end

  it 'can get the reference using the state set method' do
    mount 'Foo' do
      class Foo
        render do
          DIV(ref: set(:the_ref)) { "I am #{@the_ref}" }
        end
        after_mount do
          force_update!
        end
      end
    end
    expect(page).to have_content('I am [object HTMLDivElement]')
  end
end
