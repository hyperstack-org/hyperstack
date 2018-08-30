require 'spec_helper'

describe 'the param macro', js: true do
  it 'defines collect_other_params_as method on params proxy' do
    mount 'Foo', bar: 'biz' do
      class Foo < React::Component::Base
        collect_other_params_as :foo

        def render
          div { params.foo[:bar] }
        end
      end
    end
    expect(page.body[-35..-19]).to include("<div>biz</div>")
  end

  it "can create and access a required param" do
    mount 'Foo', foo: :bar do
      class Foo < React::Component::Base
        param :foo

        def render
          div { params.foo }
        end
      end
    end
    expect(page.body[-35..-19]).to include("<div>bar</div>")
  end

  it "can create and access an optional params" do
    mount 'Foo', foo1: :bar1, foo3: :bar3 do
      class Foo < React::Component::Base

        param foo1: :no_bar1
        param foo2: :no_bar2
        param :foo3, default: :no_bar3
        param :foo4, default: :no_bar4

        def render
          div { "#{params.foo1}-#{params.foo2}-#{params.foo3}-#{params.foo4}" }
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div>bar1-no_bar2-bar3-no_bar4</div>')
  end

  it 'can specify validation rules with the type option' do
    expect_evaluate_ruby do
      class Foo < React::Component::Base
        param :foo, type: String
      end
      Foo.prop_types
    end.to have_key('_componentValidator')
  end

  it "can type check params" do
    mount 'Foo', foo1: 12, foo2: "string" do
      class Foo < React::Component::Base

        param :foo1, type: String
        param :foo2, type: String

        def render
          div { "#{params.foo1}-#{params.foo2}" }
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div>12-string</div>')
    expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
          .to match(/Warning: Failed prop( type|Type): In component `Foo`\nProvided prop `foo1` could not be converted to String/)
  end

  it 'logs error in warning if validation failed' do
    evaluate_ruby do
      class Lorem; end
      class Foo2 < React::Component::Base
        param :foo
        param :lorem, type: Lorem
        param :bar, default: nil, type: String
        def render; div; end
      end

      React::Test::Utils.render_component_into_document(Foo2, bar: 10, lorem: Lorem.new)
    end
    expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
      .to match(/Warning: Failed prop( type|Type): In component `Foo2`\nRequired prop `foo` was not specified\nProvided prop `bar` could not be converted to String/)
  end

  it 'should not log anything if validation passes' do
    evaluate_ruby do
      class Lorem; end
      class Foo < React::Component::Base
        param :foo
        param :lorem, type: Lorem
        param :bar, default: nil, type: String

        def render; div; end
      end
      React::Test::Utils.render_component_into_document(Foo, foo: 10, bar: '10', lorem: Lorem.new)
    end
    expect(page.driver.browser.manage.logs.get(:browser).reject { |m| m.message =~ /(D|d)eprecated/ }.map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
      .not_to match(/Warning|Error/)
  end

  describe 'advanced type handling' do
    before(:each) do
      on_client do
        class Foo < React::Component::Base
          def render; ""; end
        end
      end
    end

    it "can use the [] notation for arrays" do
      mount 'Foo', foo: 10, bar: [10] do
        Foo.class_eval do
          param :foo, type: []
          param :bar, type: []
        end
      end
      expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
        .to match(/Warning: Failed prop( type|Type): In component `Foo`\nProvided prop `foo` could not be converted to Array/)
    end

    it "can use the [xxx] notation for arrays of a specific type" do
      mount 'Foo', foo: [10], bar: ["10"] do
        Foo.class_eval do
          param :foo, type: [String]
          param :bar, type: [String]
        end
      end
      expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
        .to match(/Warning: Failed prop( type|Type): In component `Foo`\nProvided prop `foo`\[0\] could not be converted to String/)
    end

    it "can convert a json hash to a type" do
      mount 'Foo', foo: "", bar: { bazwoggle: 1 }, baz: [{ bazwoggle: 2 }] do
        class BazWoggle
          def initialize(kind)
            @kind = kind
          end
          attr_accessor :kind
          def self._react_param_conversion(json, validate_only)
            new(json[:bazwoggle]) if json[:bazwoggle]
          end
        end
        Foo.class_eval do
          param :foo, type: BazWoggle
          param :bar, type: BazWoggle
          param :baz, type: [BazWoggle]
          def render
            "#{params.bar.kind}, #{params.baz[0].kind}"
          end
        end
      end
      expect(page.body[-60..-19]).to include('<span>1, 2</span>')
      expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
        .to match(/Warning: Failed prop( type|Type): In component `Foo`\nProvided prop `foo` could not be converted to BazWoggle/)
    end

    describe "converts params only once" do
      it "not on every access" do
        mount 'Foo', foo: {bazwoggle: 1} do
          class BazWoggle
            def initialize(kind)
              @kind = kind
            end
            attr_accessor :kind
            def self._react_param_conversion(json, validate_only)
              new(json[:bazwoggle]) if json[:bazwoggle]
            end
          end
          Foo.class_eval do
            param :foo, type: BazWoggle
            def render
              params.foo.kind = params.foo.kind+1
              "#{params.foo.kind}"
            end
          end
        end
        expect(page.body[-60..-19]).to include('<span>2</span>')
      end

      it "even if contains an embedded native object"
      # its not clear what this test was trying to accomplish...
      #  do
      #   pending 'Fix after merging'
      #   stub_const "Bar", Class.new(React::Component::Base)
      #   stub_const "BazWoggle", Class.new
      #   BazWoggle.class_eval do
      #     def initialize(kind)
      #       @kind = kind
      #     end
      #     attr_accessor :kind
      #     def self._react_param_conversion(json, validate_only)
      #       new(JSON.from_object(json[0])[:bazwoggle]) if JSON.from_object(json[0])[:bazwoggle]
      #     end
      #   end
      #   Bar.class_eval do
      #     param :foo, type: BazWoggle
      #     def render
      #       params.foo.kind.to_s
      #     end
      #   end
      #   Foo.class_eval do
      #     export_state :change_me
      #     before_mount do
      #       Foo.change_me! "initial"
      #     end
      #     def render
      #       Bar(foo: Native([`{bazwoggle: #{Foo.change_me}}`]))
      #     end
      #   end
      #   div = `document.createElement("div")`
      #   React.render(React.create_element(Foo, {}), div)
      #   Foo.change_me! "updated"
      #   expect(`div.children[0].innerHTML`).to eq("updated")
      # end
    end

    it "will alias a Proc type param" do
      evaluate_ruby do
        Foo.class_eval do
          param :foo, type: Proc
          def render
            params.foo
          end
        end
        React::Test::Utils.render_component_into_document(Foo, foo: lambda { 'works!' })
      end
      expect(page.body[-60..-19]).to include('<span>works!</span>')
    end

    it "will create a 'bang' (i.e. update) method if the type is React::Observable" do
      expect_evaluate_ruby do
        Foo.class_eval do
          param :foo, type: React::Observable
          before_mount do
            params.foo! "ha!"
          end
          def render
            params.foo
          end
        end
        current_state = ""
        observer = React::Observable.new(current_state) { |new_state| current_state = new_state }
        React::Test::Utils.render_component_into_document(Foo, foo: observer)
        current_state
      end.to eq("ha!")
      expect(page.body[-60..-19]).to include('<span>ha!</span>')
    end
  end
end
