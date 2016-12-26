require 'spec_helper'

if opal?

describe 'Refs callback' do
  before do
    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component
    end
  end

  it "is invoked with the actual Ruby instance" do
    stub_const 'Bar', Class.new
    Bar.class_eval do
      include React::Component
      def render
        React.create_element('div')
      end
    end

    Foo.class_eval do
      def my_bar=(bar)
        $bar = bar
      end

      def render
        React.create_element(Bar, ref: method(:my_bar=).to_proc)
      end
    end

    element = React.create_element(Foo)
    React::Test::Utils.render_into_document(element)
    expect($bar).to be_a(Bar)
    $bar = nil
  end

  it "is invoked with the actual DOM node" do
    Foo.class_eval do
      def my_div=(div)
        $div = div
      end

      def render
        React.create_element('div', ref: method(:my_div=).to_proc)
      end
    end

    element = React.create_element(Foo)
    React::Test::Utils.render_into_document(element)
    expect(`#{$div}.nodeType`).to eq(1)
    $div = nil
  end
end

end
