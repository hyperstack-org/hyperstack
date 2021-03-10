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
    expect(page).to have_content('hello')
    expect_evaluate_ruby("Hyperstack.instance_variable_get('@deprecation_messages')").to eq(
      ["Warning: Deprecated feature used in TestComp. `before_new_params` has been deprecated.  "\
       "The base method componentWillReceiveProps is deprecated in React without replacement"
     ]
   )
 end

  context "when params are expected in the before_update callback" do
    it "when providing a block" do
      mount "TestComp" do
        class TestComp < HyperComponent
          before_update { |x, y| }
          render { 'hello' }
        end
      end
      expect(page).to have_content('hello')
      expect_evaluate_ruby("Hyperstack.instance_variable_get('@deprecation_messages')").to eq(
        ["Warning: Deprecated feature used in TestComp. In the future before_update callbacks will not receive any parameters."]
      )
    end

    it "when providing a method name" do
      mount "TestComp" do
        class TestComp < HyperComponent
          def foo(x, y)
          end
          before_update :foo
          render { 'hello' }
        end
      end
      expect(page).to have_content('hello')
      expect_evaluate_ruby("Hyperstack.instance_variable_get('@deprecation_messages')").to eq(
        ["Warning: Deprecated feature used in TestComp. In the future before_update callbacks will not receive any parameters."]
      )
    end
  end

end
