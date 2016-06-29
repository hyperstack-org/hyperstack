require 'spec_helper'

if opal?
describe 'Element' do
  after(:each) do
    React::API.clear_component_class_cache
  end

  it 'renders a top level component using render with a block' do
    stub_const 'Foo', Class.new(React::Component::Base)
    Foo.class_eval do
      param :name
      def render
        "hello #{params.name}"
      end
    end
    test_div = Element.new(:div)
    test_div.render { Foo(name: 'fred') }
    expect(Element[test_div].find('span').html).to eq('hello fred')
  end

  it 'renders a top level component using render with a container and params ' do
    test_div = Element.new(:div)
    test_div.render(:span, id: :render_test_span) { 'hello' }
    expect(Element[test_div].find('#render_test_span').html).to eq('hello')
  end

  it 'will find the DOM node given a react element' do
    stub_const 'Foo', Class.new(React::Component::Base)
    Foo.class_eval do
      def render
        div { 'hello' }
      end
    end

    expect(Element[renderToDocument(Foo)].html).to eq('hello')
  end
end
end
