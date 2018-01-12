require 'spec_helper'

describe 'opal-jquery extensions', js: true do
  describe 'Element' do
    xit 'will reuse the wrapper componet class for the same Element' do
      # TODO how come a def component_will_unmount will not be received
      stub_const 'Foo', Class.new(React::Component::Base)
      Foo.class_eval do
        param :name
        def render
          "hello #{params.name}"
        end

        def component_will_unmount

        end
      end

      expect_any_instance_of(Foo).to_not receive(:component_will_unmount)

      test_div = Element.new(:div)
      test_div.render { Foo(name: 'fred') }
      test_div.render { Foo(name: 'freddy') }
      expect(Element[test_div].find('span').html).to eq('hello freddy')
    end

    it 'renders a top level component using render with a block' do
      expect_evaluate_ruby do
        class Foo < React::Component::Base
          param :name
          def render
            "hello #{params.name}"
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
        test_div.render(:span, id: :render_test_span) { 'hello' }
        Element[test_div].find('#render_test_span').html
      end.to eq('hello')
    end

    it 'will find the DOM node given a react element' do
      expect_evaluate_ruby do
        class Foo < React::Component::Base
          def render
            div { 'hello' }
          end
        end
        Element[React::Test::Utils.render_component_into_document(Foo)].html
      end.to eq('hello')
    end

    it "accepts plain js object as selector" do
      evaluate_ruby do
        Element[JS.call(:eval, "(function () { return window; })();")]
      end
      expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
          .not_to match(/Exception|Error/)
    end
  end
end
