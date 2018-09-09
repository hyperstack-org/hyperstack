require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe 'React Integration', js: true do
  it "The hyper-component gem can use hyper-store state syntax" do
    mount "TestComp" do
      class TestComp < Hyperloop::Component
        before_mount do
          mutate.foo 'hello'
        end
        render(DIV) do
          state.foo
        end
      end
    end
    expect(page).to have_content('hello')
  end
  it "and it can still use the deprecated mutate syntax" do
    mount "TestComp" do
      class TestComp < Hyperloop::Component
        before_mount do
          state.foo! 'hello'
        end
        render(DIV) do
          state.foo
        end
      end
    end
    expect(page).to have_content('hello')
  end
  it "can use the hyper-store syntax to declare component states" do
    mount "TestComp" do
      class TestComp < Hyperloop::Component
        state foo: 'hello'
        render(DIV) do
          " foo = #{state.foo}"
        end
      end
    end
    expect(page).to have_content('hello')
  end
  it "can use the hyper-store syntax to declare component states and use deprecated mutate syntax" do
    mount "TestComp" do
      class TestComp < Hyperloop::Component
        state foo: true
        after_mount do
          state.foo! 'hello' if state.foo
        end
        render(DIV) do
          state.foo
        end
      end
    end
    expect(page).to have_content('hello')
  end
  it "can still use the deprecated syntax to declare component states" do
    mount "TestComp" do
      class TestComp < Hyperloop::Component
        define_state foo: 'hello'
        render(DIV) do
          state.foo
        end
      end
    end
    expect(page).to have_content('hello')
  end
  it "can use the hyper-store syntax to declare class states" do
    mount "TestComp" do
      class TestComp < Hyperloop::Component
        state foo: 'hello', scope: :class, reader: true
        render(DIV) do
          TestComp.foo
        end
      end
    end
    expect(page).to have_content('hello')
  end
  it "can still use the deprecated syntax to declare component states" do
    mount "TestComp" do
      class TestComp < Hyperloop::Component
        export_state foo: 'hello'
        render(DIV) do
          TestComp.foo
        end
      end
    end
    expect(page).to have_content('hello')
  end

  it 'defines component spec methods' do
    mount "Foo" do
      class Foo
        include Hyperloop::Component::Mixin
        def render
          "initial_state = #{initial_state.inspect}"
        end
      end
    end
    expect(page).to have_content('initial_state = nil')
  end

  it 'allows block for life cycle callback' do
    mount "Foo" do
      class Foo < Hyperloop::Component
        before_mount do
          set_state({ foo: "bar" })
        end
        render(DIV) do
          state[:foo]
        end
      end
    end
    expect(page).to have_content('bar')
  end

  it 'allows kernal method names like "format" to be used as state variable names' do
    mount 'Foo' do
      class Foo < Hyperloop::Component
        before_mount do
          mutate.format 'hello'
        end
        render(DIV) do
          state.format
        end
      end
    end
    expect(page).to have_content('hello')
  end


end
