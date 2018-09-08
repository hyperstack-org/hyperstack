require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe 'React Integration', js: true do
  it "The hyper-component gem can use Hyperloop::Component to create components" do
    mount "TestComp" do
      class TestComp < Hyperloop::Component
        render(DIV) { 'hello'}
      end
    end
    expect(page).to have_content('hello')
    expect_evaluate_ruby("React::Component.instance_variable_get('@deprecation_messages')").to be_nil
  end
  it "The hyper-component gem can use Hyperloop::Component::Mixin to create components" do
    mount "TestComp" do
      class TestComp
        include Hyperloop::Component::Mixin
        render(DIV) { 'hello'}
      end
    end
    expect(page).to have_content('hello')
    expect_evaluate_ruby("React::Component.instance_variable_get('@deprecation_messages')").to be_nil
  end
  it "The hyper-component gem can use the deprecated React::Component::Base class to create components" do
    mount "TestComp" do
      class TestComp < React::Component::Base
        render(DIV) { 'hello'}
      end
    end
    expect(page).to have_content('hello')
    expect_evaluate_ruby("React::Component.instance_variable_get('@deprecation_messages')").to eq(
    ["Warning: Deprecated feature used in TestComp. The class name React::Component::Base has been deprecated.  Use Hyperloop::Component instead."]
    )
  end
  it "The hyper-component gem can use Hyperloop::Component::Mixin to create components" do
    mount "TestComp" do
      class TestComp
        include React::Component
        render(DIV) { 'hello'}
      end
    end
    expect(page).to have_content('hello')
    expect_evaluate_ruby("React::Component.instance_variable_get('@deprecation_messages')").to eq(
    ["Warning: Deprecated feature used in TestComp. The module name React::Component has been deprecated.  Use Hyperloop::Component::Mixin instead."]
    )
  end
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
    expect_evaluate_ruby("React::Component.instance_variable_get('@deprecation_messages')").to be_nil
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
    expect_evaluate_ruby("React::Component.instance_variable_get('@deprecation_messages')").to eq(
    ["Warning: Deprecated feature used in TestComp. The mutator 'state.foo!' has been deprecated.  Use 'mutate.foo' instead."]
    )
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
    expect_evaluate_ruby("React::Component.instance_variable_get('@deprecation_messages')").to be_nil
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
    expect_evaluate_ruby("React::Component.instance_variable_get('@deprecation_messages')").to eq(
    ["Warning: Deprecated feature used in TestComp. 'define_state' is deprecated. Use the 'state' macro to declare states."]
    )
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
    expect_evaluate_ruby("React::Component.instance_variable_get('@deprecation_messages')").to be_nil
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
    expect_evaluate_ruby("React::Component.instance_variable_get('@deprecation_messages')").to eq(
    ["Warning: Deprecated feature used in TestComp. 'export_state' is deprecated. Use the 'state' macro to declare states."]
    )
  end

  it 'defines component spec methods' do
    mount "Foo" do
      class Foo
        include React::Component
        def render
          "initial_state = #{initial_state}"
        end
      end
    end
    expect(page).to have_content('initial_state = ')
  end

  it 'allows block for life cycle callback' do
    mount "Foo" do
      class Foo < React::Component::Base
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
      class Foo < React::Component::Base
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

  # failures due to React::State::ALWAYS_UPDATE_STATE_AFTER_RENDER = true
  # these tests are all synchronous and fail if we don't react to state change during the rendering cycle.

#   1) React::Component New style setter & getter allows kernal method names like "format" to be used as state variable names
#      Failure/Error: Unable to find matching line from backtrace
#        expected 'Foo' with params '{}' to render '<div>yes</div>', but '<div></div>' was rendered.
#      # $$handle_matcher@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:36030:203
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   2) React::Component New style setter & getter returns an observer with the bang method and no arguments
#      Failure/Error: Unable to find matching line from backtrace
#        expected 'Foo' with params '{}' to render '<div>React::Observable</div>', but '<div></div>' was rendered.
#      # $$handle_matcher@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:36030:203
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   3) React::Component New style setter & getter returns the current value of a state when written
#      Failure/Error: Unable to find matching line from backtrace
#        expected 'Foo' with params '{}' to render '<div>bar</div>', but '<div></div>' was rendered.
#      # $$handle_matcher@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:36030:203
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   4) React::Component New style setter & getter can access an explicitly defined state`
#      Failure/Error: Unable to find matching line from backtrace
#      NoMethodError:
#        undefined method `after' for React::State
#      # $$set_state@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:110492:294
#      # [native code]
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   5) React::Component State setter & getter defines setter using `define_state`
#      Failure/Error: Unable to find matching line from backtrace
#      NoMethodError:
#        undefined method `after' for React::State
#      # $$set_state@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:110492:294
#      # [native code]
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   6) React::Component State setter & getter defines init state by passing a block to `define_state`
#      Failure/Error: Unable to find matching line from backtrace
#      NoMethodError:
#        undefined method `after' for React::State
#      # $$set_state@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:110492:294
#      # [native code]
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   7) React::Component State setter & getter defines getter using `define_state`
#      Failure/Error: Unable to find matching line from backtrace
#      NoMethodError:
#        undefined method `after' for React::State
#      # $$set_state@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:110492:294
#      # [native code]
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   8) React::Component State setter & getter defines multiple state accessors by passing array to `define_state`
#      Failure/Error: Unable to find matching line from backtrace
#      NoMethodError:
#        undefined method `after' for React::State
#      # $$set_state@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:110492:294
#      # [native code]
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   9) React::Component State setter & getter invokes `define_state` multiple times to define states
#      Failure/Error: Unable to find matching line from backtrace
#      NoMethodError:
#        undefined method `after' for React::State
#      # $$set_state@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:110492:294
#      # [native code]
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   10) React::Component State setter & getter can initialize multiple state variables with a block
#      Failure/Error: Unable to find matching line from backtrace
#      NoMethodError:
#        undefined method `after' for React::State
#      # $$set_state@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:110492:294
#      # [native code]
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   11) React::Component State setter & getter can mix multiple state variables with initializers and a block
#      Failure/Error: Unable to find matching line from backtrace
#      NoMethodError:
#        undefined method `after' for React::State
#      # $$set_state@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:110492:294
#      # [native code]
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   12) React::Component State setter & getter gets state in render method
#      Failure/Error: Unable to find matching line from backtrace
#      NoMethodError:
#        undefined method `after' for React::State
#      # $$set_state@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:110492:294
#      # [native code]
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   13) React::Component State setter & getter transforms state getter to Ruby object
#      Failure/Error: Unable to find matching line from backtrace
#      NoMethodError:
#        undefined method `after' for React::State
#      # $$set_state@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:110492:294
#      # [native code]
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   14) React::Component Event handling works in render method
#      Failure/Error: Unable to find matching line from backtrace
#      NoMethodError:
#        undefined method `after' for React::State
#      # $$set_state@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:110492:294
#      # [native code]
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   15) React::Observable allows to set value on Observable
#      Failure/Error: Unable to find matching line from backtrace
#      Exception:
#        null is not an object (evaluating 'instance.$dom_node().innerHTML')
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   16) React::State can create dynamically initialized exported states
#      Failure/Error: Unable to find matching line from backtrace
#      NoMethodError:
#        undefined method `after' for React::State
#      # $$set_state@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:110492:294
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   17) React::State ignores state updates during rendering
#      Failure/Error: Unable to find matching line from backtrace
#
#        expected: "<span>Boom</span>"
#             got: ""
#
#        (compared using ==)
#      # $$handle_matcher@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:36030:203
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   18) Adding state to a component (second tutorial example) produces the correct result
#      Failure/Error: Unable to find matching line from backtrace
#      NoMethodError:
#        undefined method `after' for React::State
#      # $$set_state@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:110492:294
#      # [native code]
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
#
#   19) Adding state to a component (second tutorial example) renders to the document
#      Failure/Error: Unable to find matching line from backtrace
#      NoMethodError:
#        undefined method `after' for React::State
#      # $$set_state@http://localhost:9999/assets/opal/rspec/sprockets_runner.js:110492:294
#      # [native code]
#      #
#      #   Showing full backtrace because every line was filtered out.
#      #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
#      #   RSpec::Configuration#backtrace_inclusion_patterns for more information.
end
