require 'spec_helper'

describe 'Deprecation Notices', js: true do

  it "using `defx render` will give a deprecation notice, but still allow render to work" do
    mount "TestComp" do
      class TestComp < HyperComponent
        def render
          'hello'
        end
      end
    end
    binding.pry
    expect(page).to have_content('hello')
    expect_evaluate_ruby("Hyperstack.instance_variable_get('@deprecation_messages')").to eq(
    ["Warning: Deprecated feature used in TestComp. Do not directly define the render method. Use the render macro instead."]
    )
  end
end
