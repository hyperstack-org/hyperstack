require 'spec_helper'

if RUBY_ENGINE == 'opal' 
  RSpec.describe React::Test::Utils do
    it 'simulates' do
      stub_const 'Foo', Class.new
      Foo.class_eval do
        include React::Component

        def render
          div { 'Click Me' }.on(:click) { |e| click(e) }
        end
      end

      instance = React::Test::Utils.render_into_document(React.create_element(Foo))
      expect(instance).to receive(:click)
      described_class.simulate(:click, instance.dom_node)
    end

    describe "render_into_document" do
      it "works with native element" do
        expect {
          described_class.render_into_document(React.create_element('div'))
        }.to_not raise_error
      end
    end
  end
end
