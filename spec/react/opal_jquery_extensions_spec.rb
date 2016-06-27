require 'spec_helper'

if opal?
describe 'Element' do
  after(:each) do
    React::API.clear_component_class_cache
  end

  it 'responds to render' do
    expect(Element['body']).to respond_to :render
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
