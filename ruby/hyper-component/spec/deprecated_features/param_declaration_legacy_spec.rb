require 'spec_helper'

describe 'the param macro', js: true do
  describe 'event handling' do
    before do
      on_client do
        class Foo
          include Hyperstack::Component
          param_accessor_style :legacy
        end
      end
    end

    it 'works in render method' do

      expect_evaluate_ruby do
        Foo.class_eval do

          attr_reader :clicked

          render do
            Hyperstack::Component::ReactAPI.create_element('div').on(:click) do
              @clicked = true
            end
          end
        end
        instance = Hyperstack::Component::ReactTestUtils.render_component_into_document(Foo)
        Hyperstack::Component::ReactTestUtils.simulate_click(instance)
        instance.clicked
      end.to eq(true)
    end

    it 'invokes handler on `this.props` using emit' do
      on_client do
        Foo.class_eval do
          param :on_foo_fubmit, type: Proc
          after_mount :setup

          def setup
            self.emit(:foo_submit, 'bar')
          end

          render do
            Hyperstack::Component::ReactAPI.create_element('div')
          end
        end
      end
      evaluate_ruby do
        element = Hyperstack::Component::ReactAPI.create_element(Foo).on(:foo_submit) { 'bar' }
        Hyperstack::Component::ReactTestUtils.render_into_document(element)
      end
      expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
        .to_not match(/Exception raised/)
    end

    it 'invokes handler with multiple params using emit' do
      on_client do
        Foo.class_eval do
          param :on_foo_invoked, type: Proc
          after_mount :setup

          def setup
            self.emit(:foo_invoked, [1,2,3], 'bar')
          end

          render do
            Hyperstack::Component::ReactAPI.create_element('div')
          end
        end
      end

      evaluate_ruby do
        element = Hyperstack::Component::ReactAPI.create_element(Foo).on(:foo_invoked) { return [1,2,3], 'bar' }
        Hyperstack::Component::ReactTestUtils.render_into_document(element)
      end
      expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
        .to_not match(/Exception raised/)
    end
  end

  describe 'Props' do
    describe 'this.props could be accessed through `params` method' do
      before do
        on_client do
          class Foo
            include Hyperstack::Component
            param_accessor_style :legacy
          end
        end
      end

      it 'reads from parent passed properties through `params`' do
        mount 'Foo', prop: 'foobar' do
          Foo.class_eval do
            param :prop
            render do
              Hyperstack::Component::ReactAPI.create_element('div') { params.prop }
            end
          end
        end
        expect(page.body[-40..-19]).to include("<div>foobar</div>")
      end
    end
  end

  it 'defines collect_other_params_as method on params proxy' do
    mount 'Foo', bar: 'biz' do
      class Foo < Hyperloop::Component
        param_accessor_style :legacy
        collect_other_params_as :foo

        render do
          DIV(class: :foo) { params.foo[:bar] }
        end
      end
    end
    expect(find('div.foo')).to have_content 'biz'
  end

  it 'defines collect_other_params_as method on params proxy' do
    mount 'Foo' do
      class Foo < Hyperloop::Component
        param_accessor_style :legacy
        state s: :beginning, scope: :shared
        def self.update_s(x)
          mutate.s x
        end
        render do
          Foo2(another_param: state.s)
        end
      end

      class Foo2 < Hyperloop::Component
        param_accessor_style :legacy
        collect_other_params_as :opts

        render do
          DIV(id: :tp) { params.opts[:another_param] }
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
        param_accessor_style :legacy
        param :foo

        render do
          DIV(class: :foo) { params.foo }
        end
      end
    end
    expect(find('div.foo')).to have_content 'bar'
  end

  it "can create and access an optional params" do
    mount 'Foo', foo1: :bar1, foo3: :bar3 do
      class Foo < Hyperloop::Component
        param_accessor_style :legacy

        param foo1: :no_bar1
        param foo2: :no_bar2
        param :foo3, default: :no_bar3
        param :foo4, default: :no_bar4

        render do
          DIV { "#{params.foo1}-#{params.foo2}-#{params.foo3}-#{params.foo4}" }
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div>bar1-no_bar2-bar3-no_bar4</div>')
  end

  it 'can specify validation rules with the type option' do
    expect_evaluate_ruby do
      class Foo < Hyperloop::Component
        param_accessor_style :legacy
        param :foo, type: String
      end
      Foo.prop_types
    end.to have_key('_componentValidator')
  end

  it "can type check params" do
    mount 'Foo', foo1: 12, foo2: "string" do
      class Foo < Hyperloop::Component
        param_accessor_style :legacy
        param :foo1, type: String
        param :foo2, type: String

        render do
          DIV { "#{params.foo1}-#{params.foo2}" }
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
      class Foo2 < Hyperloop::Component
        param_accessor_style :legacy
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
        param_accessor_style :legacy
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
          param_accessor_style :legacy
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
            "#{params.bar.kind}, #{params.baz[0].kind}"
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
          param_accessor_style :legacy
          param  :flag
          param  :a
          param  :b
          param  :c
          param  :d
          others :opts
          render do
            DIV(params.opts, id: :tp, class: "another-class", style: {marginLeft: 12}, data: {foo: :hi}) do
              "flag: #{params.flag}, a: #{params.a}, b: #{params.b}, c: #{params.c}, d: #{params.d}"
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
          param_accessor_style :legacy
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
              params.foo.kind = params.foo.kind+1
              "#{params.foo.kind}"
            end
          end
        end
        expect(page.body[-60..-19]).to include('<span>2</span>')
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
            params.foo.kind.to_s
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
    end

    it "will alias a Proc type param" do
      evaluate_ruby do
        Foo.class_eval do
          param :foo, type: Proc
          render do
            params.foo
          end
        end
        Hyperstack::Component::ReactTestUtils.render_component_into_document(Foo, foo: lambda { 'works!' })
      end
      expect(page.body[-60..-19]).to include('<span>works!</span>')
    end

  end
end
