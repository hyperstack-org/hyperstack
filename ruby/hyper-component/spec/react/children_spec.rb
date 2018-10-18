require 'spec_helper'

describe 'Hyperstack::Component::Children', js: true do
  describe 'with multiple child elements' do
    before :each do
      on_client do
        class InitTest
          def self.get_children
            component = Class.new do
              include Hyperstack::Component::Mixin
              def render
                div { 'lorem' }
              end
            end
            childs = [ Hyperstack::Component::ReactAPI.create_element('a'), Hyperstack::Component::ReactAPI.create_element('li') ]
            element = Hyperstack::Component::ReactAPI.create_element(component) { childs }
            el_children = element.to_n.JS[:props].JS[:children]
            children = Hyperstack::Component::Children.new(el_children)
            dom_el = JS.call(:eval, "document.body.appendChild(document.createElement('div'))")
            Hyperstack::Component::ReactAPI.render(element, dom_el)
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
        end.to eq(["Array", ["Hyperstack::Component::Element", "Hyperstack::Component::Element"]])
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
              include Hyperstack::Component::Mixin
              def render
                div { 'lorem' }
              end
            end
            childs = [ Hyperstack::Component::ReactAPI.create_element('a') ]
            element = Hyperstack::Component::ReactAPI.create_element(component) { childs }
            el_children = element.to_n.JS[:props].JS[:children]
            children = Hyperstack::Component::Children.new(el_children)
            dom_el = JS.call(:eval, "document.body.appendChild(document.createElement('div'))")
            Hyperstack::Component::ReactAPI.render(element, dom_el)
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
              include Hyperstack::Component::Mixin
              def render
                div { 'lorem' }
              end
            end
            element = Hyperstack::Component::ReactAPI.create_element(component)
            el_children = element.to_n.JS[:props].JS[:children]
            children = Hyperstack::Component::Children.new(el_children)
            dom_el = JS.call(:eval, "document.body.appendChild(document.createElement('div'))")
            Hyperstack::Component::ReactAPI.render(element, dom_el)
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

  describe 'other methods' do
    it 'responds to to_proc' do
      mount 'Children' do
        class ChildTester < HyperComponent
          render do
            DIV(id: :tp, &children)
          end
        end
        class Children < HyperComponent
          render do
            ChildTester { "one".span; "two".span; "three".span }
          end
        end
      end
      expect(page).to have_content('one')
      expect(page).to have_content('two')
      expect(page).to have_content('three')
    end
    it 'responds to render' do
      mount 'Children' do
        class ChildTester < HyperComponent
          render do
            DIV(id: :tp) { children.render }
          end
        end
        class Children < HyperComponent
          render do
            ChildTester { "one".span; "two".span; "three".span }
          end
        end
      end
      expect(page).to have_content('one')
      expect(page).to have_content('two')
      expect(page).to have_content('three')
    end
  end
end
