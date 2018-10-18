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

# TODO: these specs were removed from hyper-component and belong here

# describe 'New style setter & getter' do
#   before(:each) do
#     on_client do
#       class Foo
#         include Hyperstack::Component::Mixin
#         def render
#           div { state.foo }
#         end
#       end
#     end
#   end
#
#   it 'implicitly will create a state variable when first written' do
#     mount 'Foo' do
#       Foo.class_eval do
#         before_mount do
#           state.foo! 'bar'
#         end
#       end
#     end
#     # this was a 'have_xpath' check, but these are totally unreliable in capybara with webdrivers
#     # leading to false positives and negatives
#     # this simple check for string inclusion makes this checks reliable
#     expect(page.body[-35..-19]).to include("<div>bar</div>")
#   end
#
#   it 'allows kernal method names like "format" to be used as state variable names' do
#     mount 'Foo' do
#       Foo.class_eval do
#         before_mount do
#           state.format! 'yes'
#           state.foo! state.format
#         end
#       end
#     end
#     expect(page.body[-35..-19]).to include("<div>yes</div>")
#   end
#
#   it 'returns an observer with the bang method and no arguments' do
#     mount 'Foo' do
#       Foo.class_eval do
#         before_mount do
#           state.foo!(state.baz!.class.name)
#         end
#       end
#     end
#     expect(page.body[-50..-19]).to include("<div>React::Observable</div>")
#   end
#
#   it 'returns the current value of a state when written' do
#     mount 'Foo' do
#       Foo.class_eval do
#         before_mount do
#           state.baz! 'bar'
#           state.foo!(state.baz!('pow'))
#         end
#       end
#     end
#     expect(page.body[-35..-19]).to include("<div>bar</div>")
#   end
#
#   it 'can access an explicitly defined state`' do
#     mount 'Foo' do
#       Foo.class_eval do
#         define_state foo: :bar
#       end
#     end
#     expect(page.body[-35..-19]).to include("<div>bar</div>")
#   end
# end
#
# describe 'State setter & getter' do
#   before(:each) do
#     on_client do
#       class Foo
#         include Hyperstack::Component::Mixin
#         def render
#           Hyperstack::Component::ReactAPI.create_element('div') { 'lorem' }
#         end
#       end
#     end
#   end
#
#   it 'defines setter using `define_state`' do
#     expect_evaluate_ruby do
#       Foo.class_eval do
#         define_state :foo
#         before_mount :set_up
#         def set_up
#           mutate.foo 'bar'
#         end
#       end
#       instance = React::Test::Utils.render_component_into_document(Foo)
#       instance.state.foo
#     end.to eq('bar')
#   end
#
#   it 'defines init state by passing a block to `define_state`' do
#     expect_evaluate_ruby do
#       element_to_render = Hyperstack::Component::ReactAPI.create_element(Foo)
#       Foo.class_eval do
#         define_state(:foo) { 10 }
#       end
#       dom_el = JS.call(:eval, "document.body.appendChild(document.createElement('div'))")
#       instance = Hyperstack::Component::ReactAPI.render(element_to_render, dom_el)
#       instance.state.foo
#     end.to eq(10)
#   end
#
#   it 'defines getter using `define_state`' do
#     expect_evaluate_ruby do
#       Foo.class_eval do
#         define_state(:foo) { 10 }
#         before_mount :bump
#         def bump
#           mutate.foo(state.foo + 20)
#         end
#       end
#       instance = React::Test::Utils.render_component_into_document(Foo)
#       instance.state.foo
#     end.to eq(30)
#   end
#
#   it 'defines multiple state accessors by passing array to `define_state`' do
#     expect_evaluate_ruby do
#       Foo.class_eval do
#         define_state :foo, :foo2
#         before_mount :set_up
#         def set_up
#           mutate.foo 10
#           mutate.foo2 20
#         end
#       end
#       instance = React::Test::Utils.render_component_into_document(Foo)
#       [ instance.state.foo, instance.state.foo2 ]
#     end.to eq([10, 20])
#   end
#
#   it 'invokes `define_state` multiple times to define states' do
#     expect_evaluate_ruby do
#       Foo.class_eval do
#         define_state(:foo) { 30 }
#         define_state(:foo2) { 40 }
#       end
#       instance = React::Test::Utils.render_component_into_document(Foo)
#       [ instance.state.foo, instance.state.foo2 ]
#     end.to eq([30, 40])
#   end
#
#   it 'can initialize multiple state variables with a block' do
#     expect_evaluate_ruby do
#       Foo.class_eval do
#         define_state(:foo, :foo2) { 30 }
#       end
#       instance = React::Test::Utils.render_component_into_document(Foo)
#       [ instance.state.foo, instance.state.foo2 ]
#     end.to eq([30, 30])
#   end
#
#   it 'can mix multiple state variables with initializers and a block' do
#     expect_evaluate_ruby do
#       Foo.class_eval do
#         define_state(:x, :y, foo: 1, bar: 2) {3}
#       end
#       instance = React::Test::Utils.render_component_into_document(Foo)
#       [ instance.state.x, instance.state.y, instance.state.foo, instance.state.bar ]
#     end.to eq([3, 3, 1, 2])
#   end
#
#   it 'gets state in render method' do
#     mount 'Foo' do
#       Foo.class_eval do
#         define_state(:foo) { 10 }
#         def render
#           Hyperstack::Component::ReactAPI.create_element('div') { state.foo }
#         end
#       end
#     end
#     expect(page.body[-35..-19]).to include("<div>10</div>")
#   end
#
#   it 'supports original `setState` as `set_state` method' do
#     expect_evaluate_ruby do
#       Foo.class_eval do
#         before_mount do
#           self.set_state(foo: 'bar')
#         end
#       end
#       instance = React::Test::Utils.render_component_into_document(Foo)
#       instance.state[:foo]
#     end.to eq('bar')
#   end
#
#   it '`set_state!` method works and doesnt replace other state' do
#     # this test changed because the function replaceState is gone in react
#     expect_evaluate_ruby do
#       Foo.class_eval do
#         before_mount do
#           set_state(foo: 'bar')
#           set_state!(bar: 'lorem')
#         end
#       end
#       instance = React::Test::Utils.render_component_into_document(Foo)
#       [ instance.state[:foo], instance.state[:bar] ]
#     end.to eq(['bar', 'lorem'])
#   end
#
#   it 'supports original `state` method' do
#     mount 'Foo' do
#       Foo.class_eval do
#         before_mount do
#           self.set_state(foo: 'bar')
#         end
#
#         def render
#           div { self.state[:foo] }
#         end
#       end
#     end
#     expect(page.body[-35..-19]).to include("<div>bar</div>")
#   end
#
#   it 'transforms state getter to Ruby object' do
#     mount 'Foo' do
#       Foo.class_eval do
#         define_state :foo
#
#         before_mount do
#           mutate.foo [{a: "Hello"}]
#         end
#
#         def render
#           div { state.foo[0][:a] }
#         end
#       end
#     end
#     expect(page.body[-40..-19]).to include("<div>Hello</div>")
#   end
#
#   it 'sets initial state with default value in constructor in @native object state property' do
#     mount 'StateFoo' do
#       class StateFoo
#         include Hyperstack::Component::Mixin
#         state bar: 25
#
#         def initialize(native)
#           super(native)
#           @@initial_state = @native.JS[:state].JS[:bar]
#         end
#
#         def self.initial_state
#           @@initial_state ||= 0
#         end
#
#         def render
#           Hyperstack::Component::ReactAPI.create_element('div') { 'lorem' }
#         end
#       end
#     end
#     expect_evaluate_ruby('StateFoo.initial_state').to eq(25)
#   end

    # it 'doesnt cause extra render when setting state in :before_mount' do
    #   mount 'StateFoo' do
    #     class StateFoo
    #       include Hyperstack::Component::Mixin
    #
    #       def self.render_count
    #         @@render_count ||= 0
    #       end
    #       def self.incr_render_count
    #         @@render_count ||= 0
    #         @@render_count += 1
    #       end
    #
    #       before_mount do
    #         mutate.bar 50
    #       end
    #
    #       def render
    #         StateFoo.incr_render_count
    #         Hyperstack::Component::ReactAPI.create_element('div') { 'lorem' }
    #       end
    #     end
    #   end
    #   expect_evaluate_ruby('StateFoo.render_count').to eq(1)
    # end
