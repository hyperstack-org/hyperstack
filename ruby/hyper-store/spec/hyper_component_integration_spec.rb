require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe 'React Integration', js: true do
  it "The hyper-component gem can use hyper-store state syntax" do
    mount "TestComp" do
      class TestComp < HyperComponent
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
  it "can use the hyper-store syntax to declare component states" do
    mount "TestComp" do
      class TestComp < HyperComponent
        state foo: 'hello'
        render(DIV) do
          " foo = #{state.foo}"
        end
      end
    end
    expect(page).to have_content('hello')
  end
  it "can use the hyper-store syntax to declare class states" do
    mount "TestComp" do
      class TestComp < HyperComponent
        state foo: 'hello', scope: :class, reader: true
        render(DIV) do
          TestComp.foo
        end
      end
    end
    expect(page).to have_content('hello')
  end
  it 'defines component inspect method' do
    mount "Foo" do
      class Foo
        include Hyperstack::Component::Mixin
        def render
          "initial_state = #{initial_state.inspect}"
        end
      end
    end
    expect(page).to have_content('initial_state = nil')
  end

  it 'allows access via [] and []= operators' do
    mount "Foo" do
      class Foo < HyperComponent
        before_mount do
          mutate[:foo] = {}
          mutate[:foo][:bar] = :baz
        end
        render(DIV) do
          DIV { state[:foo][:bar] }
        end
      end
    end
    expect(page).to have_content('baz')
  end

  it 'allows kernal method names like "format" to be used as state variable names' do
    mount 'Foo' do
      class Foo < HyperComponent
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
