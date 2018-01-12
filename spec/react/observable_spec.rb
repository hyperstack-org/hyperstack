require 'spec_helper'

describe 'React::Observable', js: true do
  it "allows to set value on Observable" do
    expect_evaluate_ruby do
      class Zoo
        include React::Component
        param :foo, type: React::Observable
        before_mount do
          params.foo! 4
        end

        def render
          nil
        end
      end

      class Foo
        include React::Component

        def render
          div do
            Zoo(foo: state.foo! )
            span { state.foo.to_s }
          end
        end
      end

      instance = React::Test::Utils.render_component_into_document(Foo)
      instance.dom_node.JS[:innerHTML]
    end.to eq('<span></span><span>4</span>')
  end
end
