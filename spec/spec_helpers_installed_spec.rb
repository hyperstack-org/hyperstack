require 'spec_helper'

describe 'React DSL', :opal => true do

  it "will turn the last string in a block into a element" do
    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component
      def render
        div { "hello" }
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<div>hello</div>')
  end
end

RSpec.describe ReactiveRuby::Rails::ComponentMount, :ruby => true do
  let(:helper) { described_class.new }

  before do
    helper.setup(ActionView::TestCase::TestController.new)
  end

  describe '#react_component' do
    it 'renders a div' do
      html = helper.react_component('Components::HelloWorld')
      expect(html).to match(/<div.*><\/div>/)
    end
  end
end
