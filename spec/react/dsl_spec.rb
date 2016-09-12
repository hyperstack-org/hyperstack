require 'spec_helper'

if opal?
describe 'the React DSL' do

  context "render macro" do

    it "can define the render method with the render macro with a html tag container" do
      stub_const 'Foo', Class.new
      Foo.class_eval do
        include React::Component
        render(:div, class: :foo) do
          "hello"
        end
      end

      expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<div class="foo">hello</div>')
    end

    it "can define the render method with the render macro without a container" do
      stub_const 'Foo', Class.new
      Foo.class_eval do
        include React::Component
        render do
          "hello"
        end
      end

      expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<span>hello</span>')
    end

    it "can define the render method with the render macro with a application defined container" do
      stub_const 'Bar', Class.new(React::Component::Base)
      Bar.class_eval do
        param :p1
        render { "hello #{params.p1}" }
      end
      stub_const 'Foo', Class.new(React::Component::Base)
      Foo.class_eval do
        render Bar, p1: "fred"
      end

      expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<span>hello fred</span>')
    end
  end

  it "will turn the last string in a block into a element" do
    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component
      def render
        div { "hello" }
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<div>hello</div>')
  end

  it "will pass converted props through event handlers" do
    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component
      def render
        INPUT(data: {foo: 12}).on(:change) {}
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<input data-foo="12"/>')
  end

  it "will turn the last string in a block into a element" do
    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component
      def render
        DIV { "hello" }
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<div>hello</div>')
  end

  it "has a .span short hand String method" do
    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component
      def render
        div { "hello".span; "goodby".span }
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<div><span>hello</span><span>goodby</span></div>')
  end

  it "has a .br short hand String method" do
    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component
      def render
        div { "hello".br }
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo)).gsub("<br/>", "<br>")).to eq('<div><span>hello<br></span></div>')
  end

  it "has a .td short hand String method" do
    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component
      def render
        table { tr { "hello".td } }
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<table><tr><td>hello</td></tr></table>')
  end

  it "has a .para short hand String method" do
    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component
      def render
        div { "hello".para }
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<div><p>hello</p></div>')
  end

  it 'can do a method call on a class name that is not a direct sibling' do
    stub_const 'Mod', Module.new
    stub_const 'Mod::NestedMod', Module.new
    stub_const 'Mod::Comp', Class.new(React::Component::Base)
    Mod::Comp.class_eval do
      render { 'Mod::Comp' }
    end
    stub_const 'Mod::NestedMod::NestedComp', Class.new(React::Component::Base)
    Mod::NestedMod::NestedComp.class_eval do
      render do
        Comp()
      end
    end
    expect(React.render_to_static_markup(React.create_element(Mod::NestedMod::NestedComp)))
      .to eq('<span>Mod::Comp</span>')
  end

  it 'raises a meaningful error if a Constant Name is not actually a component' do
    stub_const 'Mod', Module.new
    stub_const 'Mod::NestedMod', Module.new
    stub_const 'Mod::Comp', Class.new
    stub_const 'Mod::NestedMod::NestedComp', Class.new(React::Component::Base)
    Mod::NestedMod::NestedComp.class_eval do
      backtrace :none
      render do
        Comp()
      end
    end
    expect { React.render_to_static_markup(React.create_element(Mod::NestedMod::NestedComp)) }
      .to raise_error('Comp does not appear to be a react component.')
  end

  it 'raises a method missing error' do
    stub_const 'Foo', Class.new(React::Component::Base)
    Foo.class_eval do
      backtrace :none
      render do
        _undefined_method
      end
    end
    expect { React.render_to_static_markup(React.create_element(Foo)) }
      .to raise_error(NoMethodError)
  end

  it "will treat the component class name as a first class component name" do
    stub_const 'Mod::Bar', Class.new
    Mod::Bar.class_eval do
      include React::Component
      def render
        "a man walks into a bar"
      end
    end
    stub_const 'Foo', Class.new(React::Component::Base)
    Foo.class_eval do
      def render
        Mod::Bar()
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<span>a man walks into a bar</span>')
  end

  it "can add class names by the haml .class notation" do
    stub_const 'Mod::Bar', Class.new
    Mod::Bar.class_eval do
      include React::Component
      collect_other_params_as :attributes
      def render
        "a man walks into a bar".span(params.attributes)
      end
    end
    stub_const 'Foo', Class.new(React::Component::Base)
    Foo.class_eval do
      def render
        Mod::Bar().the_class.other_class
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<span class="other-class the-class">a man walks into a bar</span>')
  end

  it "can use the 'class' keyword for classes" do
    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component
      def render
        span(class: "the-class") { "hello" }
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<span class="the-class">hello</span>')
  end

  it "can generate a unrendered node using the .as_node method" do          # div { "hello" }.as_node
    stub_const 'Foo', Class.new #(React::Component::Base)
    Foo.class_eval do
      include React::Component
      def render
        span(data: {size: 12}) { "hello".span.as_node.class.name }.as_node.render
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<span data-size="12">React::Element</span>')
  end

  it "can use the dangerously_set_inner_HTML param" do
    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component
      def render
        div(dangerously_set_inner_HTML:  { __html: "Hello&nbsp;&nbsp;Goodby" })
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo))).to eq('<div>Hello&nbsp;&nbsp;Goodby</div>')
  end

  it 'should convert a hash param to hyphenated html attributes if in React::HASH_ATTRIBUTES' do
    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component
      def render
        div(data: { foo: :bar }, aria: { foo_bar: :foo })
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo)))
      .to eq('<div data-foo="bar" aria-foo-bar="foo"></div>')
  end

  it 'should not convert a hash param to hyphenated html attributes if not in React::HASH_ATTRIBUTES' do
    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component
      def render
        div(title: { bar: :foo })
      end
    end

    expect(React.render_to_static_markup(React.create_element(Foo)))
      .to eq('<div title="{&quot;bar&quot;=&gt;&quot;foo&quot;}"></div>')
  end

  it "will remove all elements passed as params from the rendering buffer" do
    stub_const 'X2', Class.new
    X2.class_eval do
      include React::Component
      def render
        div do
          params[:ele].render
          params[:ele].render
        end
      end
    end
    stub_const 'Test', Class.new
    Test.class_eval do
      include React::Component
      def render
        X2(ele: b { "hello" })
      end
    end

    expect(React.render_to_static_markup(React.create_element(Test))).to eq('<div><b>hello</b><b>hello</b></div>')
  end
end
end
