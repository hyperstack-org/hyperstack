require 'spec_helper'

describe 'HAML notation', js: true do
  before(:each) do
    on_client do
      # simulate requiring 'hyperstack/component/haml'
      module Hyperstack::Internal::Component::Tags
        include Hyperstack::Internal::Component::HAMLTagInstanceMethods
      end
      class Hyperstack::Component::Element
        include Hyperstack::Internal::Component::HAMLElementInstanceMethods
      end
    end
  end
  it "can add class names by the haml .class notation" do
    mount 'Foo' do
      module Mod
        class Bar
          include Hyperstack::Component
          collect_other_params_as :attributes
          def render
            "a man walks into a bar".span(@Attributes)
          end
        end
      end
      class Foo < Hyperloop::Component
        def render
          div.div_class do
            Mod::Bar().the_class.other_class
          end
        end
      end
    end
    expect(page.body).to include('<div class="div-class"><span class="other-class the-class">a man walks into a bar</span></div>')
  end

  it 'redefines `p` to make method missing work' do
    mount 'Foo' do
      class Foo
        include Hyperstack::Component

        def render
          DIV {
            p(class_name: 'foo')
            p {}
            div { 'lorem ipsum' }
            p(id: '10')
          }
        end
      end
    end
    expect(page.body).to include('<div><p class="foo"></p><p></p><div>lorem ipsum</div><p id="10"></p></div>')
  end

  it 'only overrides `p` in render context' do
    mount 'Foo' do
      class Foo
        include Hyperstack::Component

        def self.result
          @@result ||= 'ooopsy'
        end

        def self.result_two
          @@result_two ||= 'ooopsy'
        end

        before_mount do
          @@result = p 'first'
        end

        after_mount do
          @@result_two = p 'second'
        end

        def render
          p do
            'third'
          end
        end
      end
    end
    expect_evaluate_ruby('Kernel.p "first"').to eq('first')
    expect_evaluate_ruby('p "second"').to eq('second')
    expect_evaluate_ruby('Foo.result').to eq('first')
    expect_evaluate_ruby('Foo.result_two').to eq('second')
    expect(page.body[-40..-10]).to include("<p>third</p>")
    expect(page.body[-40..-10]).not_to include("<p>first</p>")
  end
end
