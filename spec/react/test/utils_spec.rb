require 'spec_helper'

if opal?
  module React
    module Test
      class Utils
        def self.simulate(event, element)
          Simulate.new.click(element)
        end

        class Simulate
          include Native
          def initialize
            super(`React.addons.TestUtils.Simulate`)
          end

          def click(component_instance)
            `#{@native}['click']`.call(component_instance.dom_node, {})
          end
        end
      end
    end
  end
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
  end
end
