require "spec_helper"

describe 'React', js: true do
  describe "is_valid_element?" do
    it "should return true if passed a valid element" do
      
      expect_evaluate_ruby do
        element = React::Element.new(JS.call(:eval, "React.createElement('div')"))
        React.is_valid_element?(element)
      end.to eq(true)
    end

    it "should return false is passed a non React element" do
      
      expect_evaluate_ruby do
        element = React::Element.new(JS.call(:eval, "{}"))
        React.is_valid_element?(element)
      end.to eq(false)
    end
  end

  describe "create_element" do
    it "should create a valid element with only tag" do
      
      expect_evaluate_ruby do
        element = React.create_element('div')
        React.is_valid_element?(element)
      end.to eq(true)
    end

    context "with block" do
      it "should create a valid element with text as only child when block yield String" do
        
        evaluate_ruby do
          ELEMENT = React.create_element('div') { "lorem ipsum" }
        end
        expect_evaluate_ruby("React.is_valid_element?(ELEMENT)").to eq(true)
        expect_evaluate_ruby("ELEMENT.props.children").to eq("lorem ipsum")
      end

      it "should create a valid element with children as array when block yield Array of element" do
        
        evaluate_ruby do
          ELEMENT = React.create_element('div') do
            [React.create_element('span'), React.create_element('span'), React.create_element('span')]
          end
        end
        expect_evaluate_ruby("React.is_valid_element?(ELEMENT)").to eq(true)
        expect_evaluate_ruby("ELEMENT.props.children.length").to eq(3)
      end

      it "should render element with children as array when block yield Array of element" do
        
        expect_evaluate_ruby do
          element = React.create_element('div') do
            [React.create_element('span'), React.create_element('span'), React.create_element('span')]
          end
          dom_node = React::Test::Utils.render_into_document(element)
          dom_node.JS[:children].JS[:length]
        end.to eq(3)
      end
    end

    describe "custom element" do
      before :each do
        on_client do
          class Foo < React::Component::Base
            def initialize(native)
              @native = native
            end

            def render
              React.create_element("div") { "lorem" }
            end

            def props
              Hash.new(@native.JS[:props])
            end
          end
        end
      end

      it "should render element with only one children correctly" do
        
        evaluate_ruby do
          element = React.create_element(Foo) { React.create_element('span') }
          INSTANCE = React::Test::Utils.render_into_document(element)
          true
        end
        expect_evaluate_ruby("INSTANCE.props[:children].is_a?(Array)").to be_falsy
        expect_evaluate_ruby("INSTANCE.props[:children][:type]").to eq("span")
      end

      it "should render element with more than one children correctly" do
        
        evaluate_ruby do
          element = React.create_element(Foo) { [React.create_element('span'), React.create_element('span')] }
          INSTANCE = React::Test::Utils.render_into_document(element)
          true
        end
        expect_evaluate_ruby("INSTANCE.props[:children].is_a?(Array)").to be_truthy
        expect_evaluate_ruby("INSTANCE.props[:children].length").to eq(2)
      end

      it "should create a valid element provided class defined `render`" do
        
        expect_evaluate_ruby do
          element = React.create_element(Foo)
          React.is_valid_element?(element)
        end.to eq(true)
      end

      it "should allow creating with properties" do
        expect_evaluate_ruby do
          Foo.class_eval do
            param :foo
          end
          element = React.create_element(Foo, foo: "bar")
          element.props.foo
        end.to eq("bar")
      end

      it "should raise error if provided class doesn't defined `render`" do
        
        expect_evaluate_ruby do
          begin
            React.create_element(Array)
          rescue
            'failed'
          end
        end.to eq('failed')
      end

      it "should use the same instance for the same ReactComponent" do
        
        mount 'Foo' do
          Foo.class_eval do
            attr_accessor :a
            
            def initialize(n)
              self.a = 10
            end

            def component_will_mount
              self.a = 20
            end

            def render
              React.create_element("div") { self.a.to_s }
            end
          end
        end
        expect(page.body[-60..-19]).to include("<div>20</div>")
      end

      it "should match the instance cycle to ReactComponent life cycle" do
        expect_evaluate_ruby do
          Foo.class_eval do
            def initialize(native)
              @@count ||= 0
              @@count += 1
            end
            def render
              React.create_element("div")
            end
            def self.count
              @@count
            end
          end

          React::Test::Utils.render_component_into_document(Foo)
          React::Test::Utils.render_component_into_document(Foo)
          Foo.count
        end.to eq(2)
      end
    end

    describe "create element with properties" do
      it "should enforce snake-cased property name" do
        
        expect_evaluate_ruby do
          element = React.create_element("div", class_name: "foo")
          element.props.className
        end.to eq("foo")
      end

      it "should allow custom property" do
        
        expect_evaluate_ruby do
          element = React.create_element("div", foo: "bar")
          element.props.foo
        end.to eq("bar")
      end

      it "should not camel-case custom property" do
        
        expect_evaluate_ruby do
          element = React.create_element("div", foo_bar: "foo")
          element.props.foo_bar
        end.to eq("foo")
      end
    end

    describe "class_name helpers (React.addons.classSet)" do
      it "should not alter behavior when passing a string" do
        
        expect_evaluate_ruby do
          element = React.create_element("div", class_name: "foo bar")
          element.props.className
        end.to eq("foo bar")
      end
    end
  end

  describe "render" do
    it "should render element to DOM" do # was async, don know how to handle
      
      evaluate_ruby do
        DIV = JS.call(:eval, 'document.createElement("div")')
        React.render(React.create_element('span') { "lorem" }, DIV)
        '' # make to_json happy
      end
      expect_evaluate_ruby("DIV.JS[:children].JS[0].JS[:tagName]").to eq("SPAN")
      expect_evaluate_ruby("DIV.JS[:textContent]").to eq("lorem")
    end

    it "should work without providing a block" do
      expect_evaluate_ruby do
        begin
          React::Test::Utils.render_into_document(React.create_element('span') { "lorem" })
          true
        rescue
          false
        end
      end.to be_truthy
      expect(page.body[-80..-10]).to include('<div><span>lorem</span></div>')
    end

    it "returns the actual ruby instance" do
      
      expect_evaluate_ruby do
        class Foo
          def render
            React.create_element("div") { "lorem" }
          end
        end

        div = JS.call(:eval, 'document.createElement("div")')
        instance = React.render(React.create_element(Foo), div)
        instance.is_a?(Foo)
      end.to be_truthy
    end

    it "returns the actual DOM node" do
      
      expect_evaluate_ruby do
        div = JS.call(:eval, 'document.createElement("div")')
        node = React.render(React.create_element('span') { "lorem" }, div)
        node.JS['nodeType']
      end.to eq(1)
    end
  end

  describe "unmount_component_at_node" do
    it "should unmount component at node" do
      
      # was run_async
      # unmount was passed in a block run_async which passed in a block to React.render
      # trying to emulate that failed, becasue during render, _getOpalInstance was not yet defined.
      # it is defined only after render, when the component was mounted. So we call unmount after render
      expect_evaluate_ruby do
        div = JS.call(:eval, 'document.createElement("div")')
        React.render(React.create_element('span') { "lorem" }, div )
        React.unmount_component_at_node(div)
      end.to eq(true)
    end
  end
end
