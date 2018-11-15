require 'spec_helper'

describe 'event callbacks', js: true do
  it 'the triggers macro will create an event method' do
    mount 'FooBar' do
      class Foo
        include Hyperstack::Component
        triggers :foo_bar
        after_mount { foo_bar! }
        render { 'render' }
      end
      class FooBar
        include Hyperstack::Component
        include Hyperstack::State::Observable
        render do
          if @state
            DIV { @state }
          else
            Foo().on(:foo_bar) { mutate @state = 'works!' }
          end
        end
      end
    end
    expect(page).to have_content('works!')
  end

  it "the parent component does not have to supply an event handler" do
    mount 'Foo' do
      class Foo
        include Hyperstack::Component
        triggers :foo_bar
        after_mount { foo_bar! }
        render { 'render' }
      end
    end
    expect(page).to have_content('render')
  end

  it "the event name can be internally aliased" do
    mount 'FooBar' do
      class Foo
        include Hyperstack::Component
        triggers :foo_bar, alias: :foo_bar
        after_mount { foo_bar }  # notice no !
        render { 'render' }
      end
      class FooBar
        include Hyperstack::Component
        include Hyperstack::State::Observable
        render do
          if @state
            DIV { @state }
          else
            Foo().on(:foo_bar) { mutate @state = 'works!' }
          end
        end
      end
    end
    expect(page).to have_content('works!')
  end

  it "can work with builtin events" do
    mount 'Test' do
      class Btn < HyperComponent
        triggers :bungo
        Btn.class.attr_accessor :clicked
        render do
          BUTTON(id: :btn) do
            children.each(&:render)
          end.on(:click) do |evt|
            Btn.clicked = true
            bungo!
            evt.stop_propagation
          end
        end
      end
      class Test < HyperComponent
        render do
          Btn { "CLICK ME" }.on(:bungo) { toggle :clicked } unless @clicked
        end
      end
    end
    expect(page).to have_content('CLICK ME')
    expect_evaluate_ruby('Btn.clicked').to be_falsy
    find('#btn').click
    expect(page).not_to have_content('CLICK ME', wait: 0.1)
    expect_evaluate_ruby('Btn.clicked').to be_truthy
  end

  it "the event name can use a non-standard format" do
    mount 'FooBar' do
      class Foo
        include Hyperstack::Component
        triggers '<FooBar>', alias: :foo_bar!
        after_mount { foo_bar! }
        render { 'render' }
      end
      class FooBar
        include Hyperstack::Component
        include Hyperstack::State::Observable
        render do
          if @state
            DIV { @state }
          else
            Foo().on('<FooBar>') { mutate @state = 'works!' }
          end
        end
      end
    end
    expect(page).to have_content('works!')
  end
end
