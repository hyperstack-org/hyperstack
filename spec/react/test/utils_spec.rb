require 'spec_helper'

if opal?
  RSpec.describe React::Test::Utils do
    it 'simulates' do
      stub_const 'Foo', Class.new
      Foo.class_eval do
        include React::Component

        def hello
          @hello
        end

        def render
          @hello = 'hello'
          div { 'Click Me' }.on(:click) { |e| click(e) }
        end
      end

      instance = renderToDocument(Foo)
      expect_any_instance_of(Foo).to receive(:click)
      described_class.simulate(:click, instance)
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
