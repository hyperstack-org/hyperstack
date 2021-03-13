require 'spec_helper'

describe 'Deprecation Notices', js: true do

  it "using `def render` will give a deprecation notice, but still allow render to work" do
    mount "TestComp" do
      class TestComp < HyperComponent
        def render
          'hello'
        end
      end
    end
    expect(page).to have_content('hello')
    expect_evaluate_ruby("Hyperstack.instance_variable_get('@deprecation_messages')").to eq(
    ["Warning: Deprecated feature used in TestComp. Do not directly define the render method. Use the render macro instead."]
    )
  end

  it "when using before_new_params" do
    mount "TestComp" do
      class TestComp < HyperComponent
        before_new_params { 'bingo' }
        render { 'hello' }
      end
    end
    expect(page).to have_content("hello")
    expect_evaluate_ruby("Hyperstack.instance_variable_get('@deprecation_messages')").to eq(
      [
        "Warning: Deprecated feature used in TestComp. `before_new_params` has been deprecated.  "\
        "The base method componentWillReceiveProps is deprecated in React without replacement"
      ]
    )
  end

  %i[mount update].each do |callback_name|
    context "when params are expected in the before_#{callback_name} callback" do

      before(:all) do
        before_mount { CALLBACK_NAME = "before_#{callback_name}" }
      end

      it "no errors if no params" do
        mount "TestComp" do
          class TestComp < HyperComponent
            def no_params_please
              @message = "hello"
            end
            send(CALLBACK_NAME, :no_params_please)
            after_mount { mutate @message = "goodby" unless @message }
            render { @message }
          end
        end
        expect(page).to have_content('hello')
        expect_evaluate_ruby("Hyperstack.instance_variable_get('@deprecation_messages')").to be_nil
      end

      it "when providing a block" do
        mount "TestComp" do
          class TestComp < HyperComponent
            send(CALLBACK_NAME) { |x, y| @message = "hello" }
            after_mount { mutate @message = "goodby" unless @message }
            render { @message }
          end
        end
        expect(page).to have_content('hello')
        expect_evaluate_ruby("Hyperstack.instance_variable_get('@deprecation_messages')").to eq(
          ["Warning: Deprecated feature used in TestComp. In the future before_#{callback_name} callbacks will not receive any parameters."]
        )
      end

      it "when providing a method name" do
        mount "TestComp" do
          class TestComp < HyperComponent
            def foo(x, y=nil) # so it works with both before_mount (1 arg) and before_update (2 args)
              @message = "hello"
            end
            send(CALLBACK_NAME, :foo)
            after_mount { mutate @message = "goodby"  unless @message}
            render { @message }
          end
        end
        expect(page).to have_content('hello')
        expect_evaluate_ruby("Hyperstack.instance_variable_get('@deprecation_messages')").to eq(
          ["Warning: Deprecated feature used in TestComp. In the future before_#{callback_name} callbacks will not receive any parameters."]
        )
      end
    end
  end
end
