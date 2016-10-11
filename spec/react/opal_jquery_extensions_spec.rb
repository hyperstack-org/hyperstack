require 'spec_helper'

if opal?
describe 'Element' do
  after(:each) do
    React::API.clear_component_class_cache
  end

  it 'will reuse the wrapper componet class for the same Element' do
    stub_const 'Foo', Class.new(React::Component::Base)
    Foo.class_eval do
      param :name
      def render
        "hello #{params.name}"
      end

      def component_will_unmount

      end
    end

    expect_any_instance_of(Foo).to_not receive(:component_will_unmount)

    test_div = Element.new(:div)
    test_div.render { Foo(name: 'fred') }
    test_div.render { Foo(name: 'freddy') }
    expect(Element[test_div].find('span').html).to eq('hello freddy')
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

  it "accepts plain js object as selector" do
    expect {
      Element[`window`]
    }.not_to raise_error
  end
end
end
