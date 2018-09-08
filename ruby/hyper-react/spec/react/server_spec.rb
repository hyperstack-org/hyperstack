require "spec_helper"

describe 'React::Server', js: true do

  describe "render_to_string" do
    it "should render a React.Element to string" do
      client_option render_on: :both
      expect_evaluate_ruby do
        ele = React.create_element('span') { "lorem" }
        React::Server.render_to_string(ele).class.name
      end.to eq("String")
    end
  end

  describe "render_to_static_markup" do
    it "should render a React.Element to static markup" do
      client_option render_on: :both
      expect_evaluate_ruby do
        ele = React.create_element('span') { "lorem" }
        React::Server.render_to_static_markup(ele)
      end.to eq("<span>lorem</span>")
    end
  end
end

