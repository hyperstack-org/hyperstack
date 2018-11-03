require 'spec_helper'

describe 'event callbacks', js: true do
  it 'the raises macro will create an event method' do
    mount 'FooBar' do
      class Foo
        include Hyperstack::Component
        raises :foo_bar
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
        raises :foo_bar
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
        raises :foo_bar, alias: :foo_bar
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

  it "the event name can use a non-standard format" do
    mount 'FooBar' do
      class Foo
        include Hyperstack::Component
        raises '<FooBar>', alias: :foo_bar!
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
