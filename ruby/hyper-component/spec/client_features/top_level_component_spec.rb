require 'spec_helper'


describe 'Hyperstack::Internal::Component::TopLevelRailsComponent', js: true do
  before :each do
    on_client do
      module Components
        module Controller
          class Component1
            include Hyperstack::Component
            render do
              self.class.name.to_s
            end
          end
        end

        class Component1
          include Hyperstack::Component
          render do
            self.class.name.to_s
          end
        end

        class Component2
          include Hyperstack::Component
          render do
            self.class.name.to_s
          end
        end
      end

      module Controller
        class SomeOtherClass  # see issue #80
        end
      end

      class Component1
        include Hyperstack::Component
        render do
          self.class.name.to_s
        end
      end

      def render_top_level(controller, component_name)
        params = {
          controller: controller,
          component_name: component_name,
          render_params: {}
        }
        component = Hyperstack::Component::ReactTestUtils.render_component_into_document(Hyperstack::Internal::Component::TopLevelRailsComponent, params)
        component.dom_node.JS[:outerHTML]
      end
    end
  end

  it 'uses the controller name to lookup a component' do
    expect_evaluate_ruby('render_top_level("Controller", "Component1")').to eq('<span>Components::Controller::Component1</span>')
  end

  it 'can find the name without matching the controller' do
    expect_evaluate_ruby('render_top_level("Controller", "Component2")').to eq('<span>Components::Component2</span>')
  end

  it 'will find the outer most matching component' do
    expect_evaluate_ruby('render_top_level("OtherController", "Component1")').to eq('<span>Component1</span>')
  end

  it 'can find the correct component when the name is fully qualified' do
    expect_evaluate_ruby('render_top_level("Controller", "::Components::Component1")').to eq('<span>Components::Component1</span>')
  end

  describe '.html_tag?' do
    it 'is truthy for valid html tags' do
      expect_evaluate_ruby('Hyperstack::Component::ReactAPI.html_tag?("a")').to be_truthy
      expect_evaluate_ruby('Hyperstack::Component::ReactAPI.html_tag?("div")').to be_truthy
    end

    it 'is truthy for valid svg tags' do
      expect_evaluate_ruby('Hyperstack::Component::ReactAPI.html_tag?("svg")').to be_truthy
      expect_evaluate_ruby('Hyperstack::Component::ReactAPI.html_tag?("circle")').to be_truthy
    end

    it 'is falsey for invalid tags' do
      expect_evaluate_ruby('Hyperstack::Component::ReactAPI.html_tag?("tagizzle")').to be_falsey
    end
  end

  describe '.html_attr?' do
    it 'is truthy for valid html attributes' do
      expect_evaluate_ruby('Hyperstack::Component::ReactAPI.html_attr?("id")').to be_truthy
      expect_evaluate_ruby('Hyperstack::Component::ReactAPI.html_attr?("data")').to be_truthy
    end

    it 'is truthy for valid svg attributes' do
      expect_evaluate_ruby('Hyperstack::Component::ReactAPI.html_attr?("cx")').to be_truthy
      expect_evaluate_ruby('Hyperstack::Component::ReactAPI.html_attr?("strokeWidth")').to be_truthy
    end

    it 'is falsey for invalid attributes' do
      expect_evaluate_ruby('Hyperstack::Component::ReactAPI.html_tag?("attrizzle")').to be_falsey
    end
  end
end
