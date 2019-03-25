require 'spec_helper'

describe 'the param macro', js: true do
  it 'defines collect_other_params_as method on params proxy' do
    mount 'Foo', bar: 'biz' do
      class Foo < Hyperloop::Component
        collect_other_params_as :foo

        render do
          DIV { @Foo[:bar] }
        end
      end
    end
    expect(page.body[-35..-19]).to include("<div>biz</div>")
  end

  it 'can override PropsWrapper.instance_var_name' do
    mount 'Foo', bar: 'biz' do
      class Hyperstack::Internal::Component::PropsWrapper
        class << self
          def instance_var_name_for(name)
            name
          end
        end
      end

      class Foo < Hyperloop::Component
        collect_other_params_as :foo

        render do
          DIV { @foo[:bar] }
        end
      end
    end
    expect(page.body[-35..-19]).to include("<div>biz</div>")
  end

  it 'defines collect_other_params_as method on params proxy' do
    mount 'Foo' do
      class Foo < Hyperloop::Component
        state s: :beginning, scope: :shared
        def self.update_s(x)
          mutate.s x
        end
        render do
          Foo2(another_param: state.s)
        end
      end

      class Foo2 < Hyperloop::Component
        collect_other_params_as :opts

        render do
          DIV(id: :tp) { @Opts[:another_param] }
        end
      end
    end
    expect(page).to have_content('beginning')
    evaluate_ruby("Foo.update_s 'updated'")
    expect(page).to have_content('updated')
  end

  it "can create and access a required param" do
    mount 'Foo', foo: :bar do
      class Foo < Hyperloop::Component
        param :foo

        render do
          DIV { @Foo }
        end
      end
    end
    expect(page.body[-35..-19]).to include("<div>bar</div>")
  end

  it "can give a param an accessor alias" do
    mount 'Foo', foo: :bar do
      class Foo < Hyperloop::Component
        param :foo, alias: :bar

        render do
          DIV { @bar }
        end
      end
    end
    expect(page.body[-35..-19]).to include("<div>bar</div>")
  end

  it "can create and access an optional params" do
    mount 'Foo', foo1: :bar1, foo3: :bar3 do
      class Foo < Hyperloop::Component

        param foo1: :no_bar1
        param foo2: :no_bar2
        param :foo3, default: :no_bar3
        param :foo4, default: :no_bar4

        render do
          DIV { "#{@Foo1}-#{@Foo2}-#{@Foo3}-#{@Foo4}" }
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div>bar1-no_bar2-bar3-no_bar4</div>')
  end

  it 'can specify validation rules with the type option' do
    expect_evaluate_ruby do
      class Foo < Hyperloop::Component
        param :foo, type: String
      end
      Foo.prop_types
    end.to have_key('_componentValidator')
  end

  it "can type check params" do
    mount 'Foo', foo1: 12, foo2: "string" do
      class Foo < Hyperloop::Component

        param :foo1, type: String
        param :foo2, type: String

        render do
          DIV { "#{@Foo1}-#{@Foo2}" }
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div>12-string</div>')
    expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
          .to match(/Warning: Failed prop( type|Type): In component `Foo`\nProvided prop `foo1` could not be converted to String/)
  end

  it "will properly handle params named class" do
    mount 'Foo', className: 'a-class' do
      class Foo < Hyperloop::Component

        param :class

        render do
          DIV { "class = #{@Class}" }
        end
      end
    end
    expect(page).to have_content('class = a-class')
  end

  it 'logs error in warning if validation failed' do
    evaluate_ruby do
      class Lorem; end
      class Foo2 < Hyperloop::Component
        param :foo
        param :lorem, type: Lorem
        param :bar, default: nil, type: String
        render { DIV }
      end

      Hyperstack::Component::ReactTestUtils.render_component_into_document(Foo2, bar: 10, lorem: Lorem.new)
    end
    expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
      .to match(/Warning: Failed prop( type|Type): In component `Foo2`\nRequired prop `foo` was not specified\nProvided prop `bar` could not be converted to String/)
  end

  it 'should not log anything if validation passes' do
    evaluate_ruby do
      class Lorem; end
      class Foo < Hyperloop::Component
        param :foo
        param :lorem, type: Lorem
        param :bar, default: nil, type: String

        render { DIV }
      end
      Hyperstack::Component::ReactTestUtils.render_component_into_document(Foo, foo: 10, bar: '10', lorem: Lorem.new)
    end
    expect(page.driver.browser.manage.logs.get(:browser).reject { |m| m.message =~ /(D|d)eprecated/ }.map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
      .not_to match(/Warning|Error/)
  end

  describe 'advanced type handling' do
    before(:each) do
      on_client do
        class Foo < Hyperloop::Component
          render { "" }
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
          render do
            "#{@Bar.kind}, #{@Baz[0].kind}"
          end
        end
      end
      expect(page.body[-60..-19]).to include('<span>1, 2</span>')
      expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
        .to match(/Warning: Failed prop( type|Type): In component `Foo`\nProvided prop `foo` could not be converted to BazWoggle/)
    end

    it 'allows passing and merging complex arguments to params' do
      mount 'Tester' do
        class TakesParams < Hyperloop::Component
          param  :flag
          param  :a
          param  :b
          param  :c
          param  :d
          others :opts
          render do
            DIV(@Opts, id: :tp, class: "another-class", style: {marginLeft: 12}, data: {foo: :hi}) do
              "flag: #{@Flag}, a: #{@A}, b: #{@B}, c: #{@C}, d: #{@D}"
            end
          end
        end
        class Tester < Hyperloop::Component
          render do
            TakesParams(
              :flag,
              {a: 1, b: 2, class: [:x, :y], className: 'foo', class_name: 'bar baz', style: {marginRight: 12}, data: {bar: :there}},
              c: 3, d: 4
            )
          end
        end
      end
      tp = find('#tp')
      expect(tp[:class].split).to contain_exactly("x", "y", "foo", "bar", "baz", "another-class")
      expect(tp[:style]).to match('margin-right: 12px')
      expect(tp[:style]).to match('margin-left: 12px')
      expect(tp['data-foo']).to eq("hi")
      expect(tp['data-bar']).to eq("there")
      expect(tp).to have_content('flag: true, a: 1, b: 2, c: 3, d: 4')
    end

    it 'allows passing nil for class and style params' do
      mount 'Tester' do
        class Tester < Hyperloop::Component
          render do
            DIV(id: 'tp', class: nil, style: nil) { 'Tester' }
          end
        end
      end

      tp = find('#tp')

      expect(tp[:class]).to eq('')
      expect(tp[:style]).to eq('')
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
            render do
              @Foo.kind = @Foo.kind+1
              "#{@Foo.kind}"
            end
          end
        end
        expect(page.body[-60..-19]).to include('<span>2</span>')
      end

      it "will alias a Proc type param" do
        evaluate_ruby do
          Foo.class_eval do
            param :foo, type: Proc
            render do
              @Foo.call
            end
          end
          Hyperstack::Component::ReactTestUtils.render_component_into_document(Foo, foo: lambda { 'works!' })
        end
        expect(page.body[-60..-19]).to include('<span>works!</span>')
      end

      it "even if contains an embedded native object", skip: 'its not clear what this test was trying to accomplish...' do
        stub_const "Bar", Class.new(Hyperloop::Component)
        stub_const "BazWoggle", Class.new
        BazWoggle.class_eval do
          def initialize(kind)
            @kind = kind
          end
          attr_accessor :kind
          def self._react_param_conversion(json, validate_only)
            new(JSON.from_object(json[0])[:bazwoggle]) if JSON.from_object(json[0])[:bazwoggle]
          end
        end
        Bar.class_eval do
          param :foo, type: BazWoggle
          render do
            @Foo.kind.to_s
          end
        end
        Foo.class_eval do
          export_state :change_me
          before_mount do
            Foo.change_me! "initial"
          end
          render do
            Bar(foo: Native([`{bazwoggle: #{Foo.change_me}}`]))
          end
        end
        a_div = `document.createElement("div")`
        Hyperstack::Component::ReactAPI.render(Hyperstack::Component::ReactAPI.create_element(Foo, {}), a_div)
        Foo.change_me! "updated"
        expect(`div.children[0].innerHTML`).to eq("updated")
      end

      it "can use accessor style param names" do
        mount 'TestAccessorStyle', loaded: true, foo_bar: "WORKS!" do
          class TestAccessorStyle
            include Hyperstack::Component
            param_accessor_style :accessors
            param :foo_bar
            param :loaded, alias: :loaded?
            render(DIV) do
              foo_bar if loaded?
            end
          end
        end
        expect(page).to have_content('WORKS!')
      end
    end
  end
end
