require 'spec_helper'

describe 'opal-jquery extensions', js: true do
  describe 'Element' do
    it 'will render a block into an element' do
      expect_evaluate_ruby do
        class Foo < HyperComponent
          param :name
          def render
            "hello #{@name}"
          end
        end
        test_div = Element.new(:div)
        test_div.render { Foo(name: 'fred') }
        Element[test_div].find('span').html
      end.to eq('hello fred')
    end

    it 'renders a top level component using render with a container and params ' do
      expect_evaluate_ruby do
        test_div = Element.new(:div)
        test_div.render(SPAN, id: :render_test_span) { 'hello' }
        Element[test_div].find('#render_test_span').html
      end.to eq('hello')
    end

    it 'will reuse the wrapper component class for the same Element' do
      evaluate_ruby do
        class Foo < HyperComponent
          param :name
          before_mount do
            @render_count = 0
          end

          def render
            "hello #{@name} render-count: #{@render_count += 1}"
          end

          def self.rec_cnt
            @@rec_cnt ||= 0
          end
          before_unmount do
            @@rec_cnt ||= 0
            @@rec_cnt += 1
          end
        end
      end
      expect_evaluate_ruby do
        test_div = Element.new(:div)
        test_div.render { Foo(name: 'fred') }
        test_div.render { Foo(name: 'freddy') }
        [ Element[test_div].find('span').html, Foo.rec_cnt]
      end.to eq(['hello freddy render-count: 2', 0])
      expect_evaluate_ruby do
        class Foo < HyperComponent
          param :name
          def render
            "hello #{@name}"
          end
        end
        test_div = Element.new(:div)
        test_div.render(Foo, name: 'fred')
        test_div.render(Foo, name: 'freddy')
        [ Element[test_div].find('span').html, Foo.rec_cnt]
      end.to eq(['hello freddy', 0])
    end

    it 'will use the ref call back to get the component' do
      expect_promise do
        test_div = Element.new(:div)
        Promise.new.then { |c| Element[c].html }.tap do |p|
          test_div.render(SPAN, id: :render_test_span, ref: p.method(:resolve)) { 'hello' }
        end
      end.to eq('hello')
    end

    it 'will find the DOM node given a react element' do
      expect_evaluate_ruby do
        class Foo < HyperComponent
          def render
            DIV { 'hello' }
          end
        end
        Element[Hyperstack::Component::ReactTestUtils.render_component_into_document(Foo)].html
      end.to eq('hello')
    end

    it "accepts plain js object as selector" do
      evaluate_ruby do
        Element[JS.call(:eval, "(function () { return window; })();")]
      end
      expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
          .not_to match(/Exception|Error/)
    end

    it "can dynamically mount components" do
      on_client do
        class DynoMount < HyperComponent
          render(DIV) { 'I got rendered' }
        end
      end
      mount 'MountPoint' do
        class MountPoint < HyperComponent
          render(DIV) do
            # simulate what react-rails render_component output
            DIV(
              'data-react-class' => 'Hyperstack.Internal.Component.TopLevelRailsComponent',
              'data-react-props' => '{"render_params": {}, "component_name": "DynoMount", "controller": ""}'
            )
          end
        end
      end
      evaluate_ruby do
        Element['body'].mount_components
      end
      expect(page).to have_content('I got rendered')
    end
  end
end
