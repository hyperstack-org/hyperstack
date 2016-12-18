require "spec_helper"

if opal?

RSpec.describe React::Server do
  after(:each) do
    React::API.clear_component_class_cache
  end

  describe "render_to_string" do
    it "should render a React.Element to string" do
      ele = React.create_element('span') { "lorem" }
      expect(React::Server.render_to_string(ele)).to be_kind_of(String)
    end
  end

  describe "render_to_static_markup" do
    it "should render a React.Element to static markup" do
      ele = React.create_element('span') { "lorem" }
      expect(React::Server.render_to_static_markup(ele)).to eq("<span>lorem</span>")
    end
  end
end

end
