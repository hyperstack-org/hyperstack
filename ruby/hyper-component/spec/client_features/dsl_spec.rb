require 'spec_helper'

describe 'the React DSL', js: true do

  context "render macro" do

    it "can define the render method with the render macro with a html tag container" do
      mount 'Foo' do
        class Foo
          include Hyperstack::Component
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
          include Hyperstack::Component
          render do
            "hello"
          end
        end
      end
      expect(page.body[-60..-19]).to include('<span>hello</span>')
    end

    it "can define the render method with the render macro with a application defined container" do
      on_client do
        class Bar < Hyperloop::Component
          param :p1
          render { "hello #{@P1}" }
        end
        class Foo < Hyperloop::Component
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
        include Hyperstack::Component
        render do
          DIV { "hello" }
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div>hello</div>')
  end

  it "in prerender will pass converted props through event handlers", :prerendering_on do
    client_option render_on: :both
    mount 'Foo' do
      class Foo
        include Hyperstack::Component
        render do
          INPUT(data: {foo: 12}).on(:change) {}
        end
      end
    end

    expect(find('input')['data-reactroot']).to eq('')
    expect(find('input')['data-foo']).to eq('12')
  end

  it "will turn the last string in a block into a element" do
    mount 'Foo' do
      class Foo
        include Hyperstack::Component
        render do
          DIV { "hello" }
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div>hello</div>')
  end

  it "has a .span short hand String method" do
    mount 'Foo' do
      class Foo
        include Hyperstack::Component
        render do
          DIV { "hello".span; "goodby".span }
        end
      end
    end
    expect(page.body[-70..-19]).to include('<div><span>hello</span><span>goodby</span></div>')
  end

  it "in prerendering has a .br short hand String method", :prerendering_on do
    client_option render_on: :server_only
    client_option raise_on_js_errors: :off
    mount 'Foo' do
      class Foo
        include Hyperstack::Component
        render do
          DIV(class: :foo) { "hello".br }
        end
      end
    end
    expect(
      find(
        'div[data-react-class="Hyperstack.Internal.Component.TopLevelRailsComponent"] div.foo'
      )['innerHTML']
    ).to eq 'hello<br>'
  end

  it "has a .td short hand String method" do
    mount 'Foo' do
      class Foo
        include Hyperstack::Component
        render do
          TABLE {
            TBODY {
              TR { "hello".td }
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
        include Hyperstack::Component
        render do
          DIV { "hello".para }
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
          include Hyperstack::Component
          param :test
          render do
             "Mod::Comp"
          end
        end
        module NestedMod
          class NestedComp
            include Hyperstack::Component
            render do
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
          class NestedComp < Hyperloop::Component
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

  it 'raises a method missing error', :prerendering_on do
    client_option render_on: :both
    client_option raise_on_js_errors: :off
    expect_evaluate_ruby do
      class Foo < Hyperloop::Component
        backtrace :none
        render do
          _undefined_method
        end
      end
      begin
        Hyperstack::Component::ReactTestUtils.render_component_into_document(Foo)
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
          include Hyperstack::Component
          render do
            "a man walks into a bar"
          end
        end
      end
      class Foo < Hyperloop::Component
        render do
          Mod::Bar()
        end
      end
    end
    expect(page.body[-60..-19]).to include('<span>a man walks into a bar</span>')
  end


  it "can use the 'class' keyword for classes" do
    mount 'Foo' do
      class Foo
        include Hyperstack::Component
        render do
          SPAN(class: "the-class") { "hello" }
        end
      end
    end
    expect(page.body[-60..-19]).to include('<span class="the-class">hello</span>')
  end

  it "can generate a unrendered node using the ~ operator" do
    mount 'Foo' do
      class Foo
        include Hyperstack::Component
        render do
          (~SPAN(data: {size: 12}) { (~"hello".span).class.name }).render
        end
      end
    end
    expect(page.body[-80..-19]).to include('<span data-size="12">Hyperstack::Component::Element</span>')
  end

  it "~ operator removes the node from the render buffer" do
    mount 'Foo' do
      class Foo < Hyperloop::Component
        render { "hello".span; ~"goodby".span }
      end
    end
    expect(find('span').text).to eq('hello')
  end

  it "has a dom_node method" do
    mount 'Foo' do
      class Foo
        include Hyperstack::Component
        include Hyperstack::State::Observable
        after_mount { mutate @my_node_id = jQ[dom_node].id }
        render do
          SPAN(id: 'foo') { "my id is '#{@my_node_id}'" }
        end
      end
    end
    expect(page).to have_content("my id is 'foo'")
  end

  it "can use the dangerously_set_inner_HTML param" do
    mount 'Foo' do
      class Foo
        include Hyperstack::Component
        render do
          DIV(dangerously_set_inner_HTML:  { __html: "Hello and Goodby" })
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div>Hello and Goodby</div>')
  end

  it 'should convert a hash param to hyphenated html attributes if in React::HASH_ATTRIBUTES' do
    mount 'Foo' do
      class Foo
        include Hyperstack::Component
        render do
          DIV(data: { foo: :bar }, aria: { label: "title" })
        end
      end
    end
    expect(page.body[-70..-19]).to include('<div data-foo="bar" aria-label="title"></div>')
  end

  it 'should not convert a hash param to hyphenated html attributes if not in React::HASH_ATTRIBUTES' do
    mount 'Foo' do
      class Foo
        include Hyperstack::Component
        render do
          DIV(id: :div, title: { bar: :foo }) { 'the div' }
        end
      end
    end
    expect(find('#div')['title']).to eq('{"bar"=>"foo"}')
  end

  it "will remove all elements passed as params from the rendering buffer" do
    mount 'Foo' do
      class X2
        include Hyperstack::Component
        param :ele
        render do
          DIV do
            @Ele.render
            @Ele.render
          end
        end
      end
      class Foo
        include Hyperstack::Component
        render do
          X2(ele: B { "hello" })
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div><b>hello</b><b>hello</b></div>')
  end
end
