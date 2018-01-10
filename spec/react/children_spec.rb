require 'spec_helper'

describe 'React::Children', js: true do
  describe 'with multiple child elements' do
    before :each do
      on_client do
        class InitTest
          def self.get_children
            component = Class.new do
              include React::Component
              def render
                div { 'lorem' }
              end
            end
            childs = [ React.create_element('a'), React.create_element('li') ]
            element = React.create_element(component) { childs }
            el_children = element.to_n.JS[:props].JS[:children]
            children = React::Children.new(el_children)
            dom_el = JS.call(:eval, "document.body.appendChild(document.createElement('div'))")
            React.render(element, dom_el)
            children
          end
        end
      end
    end

    it 'is enumerable' do
      expect_evaluate_ruby do
        InitTest.get_children.map { |elem| elem.element_type }
      end.to eq(['a', 'li'])
    end

    it 'returns an Enumerator when not providing a block' do
      expect_evaluate_ruby do
        nodes = InitTest.get_children.each
        [nodes.class.name, nodes.size]
      end.to eq(["Enumerator", 2])
    end

    describe '#each' do
      it 'returns an array of elements' do
        expect_evaluate_ruby do
          nodes = InitTest.get_children.each { |elem| elem.element_type }
          [nodes.class.name, nodes.map(&:class)]
        end.to eq(["Array", ["React::Element", "React::Element"]])
      end
    end

    describe '#length' do
      it 'returns the number of child elements' do
        expect_evaluate_ruby do
          InitTest.get_children.length
        end.to eq(2)
      end
    end
  end

  describe 'with single child element' do
    before :each do
      on_client do
        class InitTest
          def self.get_children
            component = Class.new do
              include React::Component
              def render
                div { 'lorem' }
              end
            end
            childs = [ React.create_element('a') ]
            element = React.create_element(component) { childs }
            el_children = element.to_n.JS[:props].JS[:children]
            children = React::Children.new(el_children)
            dom_el = JS.call(:eval, "document.body.appendChild(document.createElement('div'))")
            React.render(element, dom_el)
            children
          end
        end
      end
    end

    it 'is enumerable containing single element' do
      expect_evaluate_ruby do
        InitTest.get_children.map { |elem| elem.element_type }
      end.to eq(["a"])
    end

    describe '#length' do
      it 'returns the number of child elements' do
        expect_evaluate_ruby do
          InitTest.get_children.length
        end.to eq(1)
      end
    end
  end

  describe 'with no child element' do
    before :each do
      on_client do
        class InitTest
          def self.get_children
            component = Class.new do
              include React::Component
              def render
                div { 'lorem' }
              end
            end
            element = React.create_element(component)
            el_children = element.to_n.JS[:props].JS[:children]
            children = React::Children.new(el_children)
            dom_el = JS.call(:eval, "document.body.appendChild(document.createElement('div'))")
            React.render(element, dom_el)
            children
          end
        end
      end
    end

    it 'is enumerable containing no elements' do
      expect_evaluate_ruby do
        InitTest.get_children.map { |elem| elem.element_type }
      end.to eq([])
    end

    describe '#length' do
      it 'returns the number of child elements' do
        expect_evaluate_ruby do
          InitTest.get_children.length
        end.to eq(0)
      end
    end
  end
end
