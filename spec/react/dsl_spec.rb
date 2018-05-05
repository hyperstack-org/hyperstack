require 'spec_helper'

describe 'the React DSL', js: true do

  context "render macro" do

    it "can define the render method with the render macro with a html tag container" do
      mount 'Foo' do
        class Foo
          include React::Component
          render(:div, class: :foo) do
            "hello"
          end
        end
      end
      expect(page.body[-60..-19]).to include('<div class="foo">hello</div>')
    end

    it "can define the render method with the render macro without a container" do
      mount 'Foo' do
        class Foo
          include React::Component
          render do
            "hello"
          end
        end
      end
      expect(page.body[-60..-19]).to include('<span>hello</span>')
    end

    it "can define the render method with the render macro with a application defined container" do
      on_client do
        class Bar < React::Component::Base
          param :p1
          render { "hello #{params.p1}" }
        end
        class Foo < React::Component::Base
          render Bar, p1: "fred"
        end
      end
      mount 'Foo'
      expect(page.body[-60..-19]).to include('<span>hello fred</span>')
    end
  end

  it "will turn the last string in a block into a element" do
    mount 'Foo' do
      class Foo
        include React::Component
        def render
          div { "hello" }
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div>hello</div>')
  end

  it "in prerender will pass converted props through event handlers" do
    client_option render_on: :both
    mount 'Foo' do
      class Foo
        include React::Component
        def render
          INPUT(data: {foo: 12}).on(:change) {}
        end
      end
    end
    expect(page.body).to match(/<input data-foo="12" data-reactroot="" \/>/)
  end

  it "will turn the last string in a block into a element" do
    mount 'Foo' do
      class Foo
        include React::Component
        def render
          DIV { "hello" }
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div>hello</div>')
  end

  it "has a .span short hand String method" do
    mount 'Foo' do
      class Foo
        include React::Component
        def render
          div { "hello".span; "goodby".span }
        end
      end
    end
    expect(page.body[-70..-19]).to include('<div><span>hello</span><span>goodby</span></div>')
  end

  it "in prerendering has a .br short hand String method" do
    client_option render_on: :both
    client_option raise_on_js_errors: :off
    mount 'Foo' do
      class Foo
        include React::Component
        def render
          div { "hello".br }
        end
      end
    end
    expect(page.body[-285..-233]).to match(/(<div data-reactroot=""|<div)><span>hello<(br|br\/|br \/)><\/span><\/div>/)
  end

  it "has a .td short hand String method" do
    mount 'Foo' do
      class Foo
        include React::Component
        def render
          table {
            tbody {
              tr { "hello".td }
            }
          }
        end
      end
    end
    expect(page.body[-90..-19]).to include('<table><tbody><tr><td>hello</td></tr></tbody></table>')
  end

  it "has a .para short hand String method" do
    mount 'Foo' do
      class Foo
        include React::Component
        def render
          div { "hello".para }
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div><p>hello</p></div>')
  end

  it 'can do a method call on a class name that is not a direct sibling' do
    # this test is failing because Comp() is not serialized/compiled to a method call,
    # but instead to a $scope.get("Comp"); which returns the Component Class Mod::Comp
    # instead it sould serialize/compile to a $scope.$Comp();
    # this is a bug in unparser, workaround is to pass a argument to comp
    mount 'Mod::NestedMod::NestedComp' do
      module Mod
        class Comp
          include React::Component
          param :test
          def render
             "Mod::Comp"
          end
        end
        module NestedMod
          class NestedComp
            include React::Component
            def render
              Comp(test: 'string')
            end
          end
        end
      end
    end
    expect(page.body[-60..-19]).to include('<span>Mod::Comp</span>')
  end

  it 'raises a meaningful error if a Constant Name is not actually a component' do
    client_option raise_on_js_errors: :off
    mount 'Mod::NestedMod::NestedComp' do
      module Mod
        module NestedMod
          class NestedComp < React::Component::Base
            backtrace :none
            render do
              Comp(test: 'string')
            end
          end
        end
        class Comp; end
      end
    end
    expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
          .to match(/Comp does not appear to be a react component./)
  end

  it 'raises a method missing error' do
    client_option render_on: :both
    client_option raise_on_js_errors: :off
    expect_evaluate_ruby do
      class Foo < React::Component::Base
        backtrace :none
        render do
          _undefined_method
        end
      end
      begin
        React::Test::Utils.render_component_into_document(Foo)
        'not raised'
      rescue NoMethodError
        'raised for sure!'
      end
    end.to eq('raised for sure!')

  end

  it "will treat the component class name as a first class component name" do
    mount 'Foo' do
      module Mod
        class Bar
          include React::Component
          def render
            "a man walks into a bar"
          end
        end
      end
      class Foo < React::Component::Base
        def render
          Mod::Bar()
        end
      end
    end
    expect(page.body[-60..-19]).to include('<span>a man walks into a bar</span>')
  end

  it "can add class names by the haml .class notation" do
    mount 'Foo' do
      module Mod
        class Bar
          include React::Component
          collect_other_params_as :attributes
          def render
            "a man walks into a bar".span(params.attributes)
          end
        end
      end
      class Foo < React::Component::Base
        def render
          Mod::Bar().the_class.other_class
        end
      end
    end
    expect(page.body[-90..-19]).to include('<span class="other-class the-class">a man walks into a bar</span>')
  end

  it "can use the 'class' keyword for classes" do
    mount 'Foo' do
      class Foo
        include React::Component
        def render
          span(class: "the-class") { "hello" }
        end
      end
    end
    expect(page.body[-60..-19]).to include('<span class="the-class">hello</span>')
  end

  it "can generate a unrendered node using the .as_node method" do          # div { "hello" }.as_node
    mount 'Foo' do
      class Foo
        include React::Component
        def render
          span(data: {size: 12}) { "hello".span.as_node.class.name }.as_node.render
        end
      end
    end
    expect(page.body[-80..-19]).to include('<span data-size="12">React::Element</span>')
  end

  it "can use the dangerously_set_inner_HTML param" do
    mount 'Foo' do
      class Foo
        include React::Component
        def render
          div(dangerously_set_inner_HTML:  { __html: "Hello and Goodby" })
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div>Hello and Goodby</div>')
  end

  it 'should convert a hash param to hyphenated html attributes if in React::HASH_ATTRIBUTES' do
    mount 'Foo' do
      class Foo
        include React::Component
        def render
          div(data: { foo: :bar }, aria: { label: "title" })
        end
      end
    end
    expect(page.body[-70..-19]).to include('<div data-foo="bar" aria-label="title"></div>')
  end

  it 'should not convert a hash param to hyphenated html attributes if not in React::HASH_ATTRIBUTES' do
    mount 'Foo' do
      class Foo
        include React::Component
        def render
          div(title: { bar: :foo })
        end
      end
    end
    expect(page.body[-80..-19]).to include('<div title="{&quot;bar&quot;=&gt;&quot;foo&quot;}"></div>')
  end

  it "will remove all elements passed as params from the rendering buffer" do
    mount 'Foo' do
      class X2
        include React::Component
        param :ele
        def render
          div do
            params[:ele].render
            params[:ele].render
          end
        end
      end
      class Foo
        include React::Component
        def render
          X2(ele: b { "hello" })
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div><b>hello</b><b>hello</b></div>')
  end
end
