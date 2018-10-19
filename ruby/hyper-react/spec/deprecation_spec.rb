require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe 'React Integration', js: true do
  it "The hyper-react gem can use the deprecated React::Component::Base class to create components" do
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
  it "The hyper-react gem can use React::Component to create components" do
    mount "TestComp" do
      class TestComp
        include React::Component
        render(DIV) { 'hello'}
      end
    end
    expect(page).to have_content('hello')
    expect_evaluate_ruby("React::Component.instance_variable_get('@deprecation_messages')").to eq(
    ["Warning: Deprecated feature used in TestComp. The module name React::Component has been deprecated.  Use Hyperloop::Component instead."]
    )
  end
end
