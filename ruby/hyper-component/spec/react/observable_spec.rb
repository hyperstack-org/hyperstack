require 'spec_helper'

describe 'React::Observable', js: true do
  it "allows to set value on Observable" do
    mount 'Foo' do
      class Zoo
        include Hyperloop::Component::Mixin
        param :foo, type: React::Observable
        before_mount do
          params.foo! 4
        end

        def render
          nil
        end
      end

      class Foo
        include Hyperloop::Component::Mixin

        def render
          div do
            Zoo(foo: state.foo! )
            span { state.foo.to_s }
          end
        end
      end
    end
    expect(page.body[-60..-19]).to include('<span></span><span>4</span>')
  end
end
