require 'spec_helper'
# This definitely is work in progress
describe "React::NativeLibrary", js: true do
  before :each do
    on_client do
      module NativeLibraryTestModule
        class Component < React::Component::Base
          param :time_stamp
          backtrace :none
          render { NativeComponent(name: "There - #{params.time_stamp}") }
        end
      
        class NestedComponent < React::Component::Base
          param :time_stamp
          backtrace :none
          render { NativeLibrary::NativeNestedLibrary::NativeComponent(name: "There - #{params.time_stamp}") }
        end
      end
    end
    evaluate_ruby do
      "this makes sure React is loaded"
    end
  end

  # after(:each) do
  #   %x{
  #     delete window.NativeLibrary;
  #     delete window.NativeComponent;
  #     delete window.nativeLibrary;
  #     delete window.nativeComponent;
  #     delete window.NativeObject;
  #   }
  #   Object.send :remove_const, :NativeLibrary
  #   Object.send :remove_const, :NativeComponent
  # end

  describe "functional stateless component (supported in reactjs v14+ only)" do
    xit "is detected as native React.js component by `native_react_component?`" do
      # TODO: needs some work
      expect_evaluate_ruby do
        React::API.native_react_component?(JS.call(:eval, "function C(){ return null }"))
      end.to be_truthy
    end

    xit "imports a React.js functional stateless component" do
      # TODO: needs some work
      page.execute_script('window.NativeLibrary = {
            FunctionalComponent: function HelloMessage(props){
              return React.createElement("div", null, "Hello ", props.name);
            }
          }')
      evaluate_ruby do
        class Foo < React::Component::Base
          imports "NativeLibrary.FunctionalComponent"
        end
        React::Test::Utils.render_component_into_document(Foo, name: "There")
      end
      expect(page.body[-60..-19]).to include('<div>Hello There</div>')
    end
  end

  it "can use native_react_component? to detect a native React.js component" do
    page.execute_script('window.NativeComponent = class extends React.Component {
      constructor(props) {
        super(props);
        this.displayName = "HelloMessage";
      }
      render() { return React.createElement("div", null, "Hello ", this.props.name); }
    }')
    expect_evaluate_ruby do
      React::API.native_react_component?(JS.call(:eval, 'window.NativeComponent'))
    end.to be_truthy
    expect_evaluate_ruby do
      React::API.native_react_component?(JS.call(:eval, '{render: function render() {}}'))
    end.to be_falsy
    expect_evaluate_ruby do
      React::API.native_react_component?(JS.call(:eval, 'window.DoesntExist'))
    end.to be_falsy
    expect_evaluate_ruby do
      React::API.native_react_component?()
    end.to be_falsy
  end

  xit "will import a React.js library into the Ruby name space" do
    # TODO needs work
    page.execute_script('window.NativeLibrary = {
      NativeComponent: class extends React.Component {
      constructor(props) {
        super(props);
        this.displayName = "HelloMessage";
      }
      render() { return React.createElement("div", null, "Hello ", this.props.name); }
    }}')

    mount 'Foo::NativeComponent', name: "There" do
      class Foo < React::NativeLibrary
        imports "NativeLibrary"
      end
    end
    expect(page.body[-60..-19]).to include('<div>Hello There</div>')
  end

  xit "will import a nested React.js library into the Ruby name space" do
    # TODO needs work
    %x{
      window.NativeLibrary = {
        NestedLibrary: {
          NativeComponent: React.createClass({
            displayName: "HelloMessage",
            render: function render() {
              return React.createElement("div", null, "Hello ", this.props.name);
            }
        })}
      }
    }
    stub_const 'Foo', Class.new(React::NativeLibrary)
    Foo.class_eval do
      imports "NativeLibrary"
    end
    expect(Foo::NestedLibrary::NativeComponent)
      .to render_static_html('<div>Hello There</div>').with_params(name: "There")
  end

  xit "will rename an imported a React.js component" do
    # TODO needs work
    %x{
      window.NativeLibrary = {
        NativeComponent: React.createClass({
          displayName: "HelloMessage",
          render: function render() {
            return React.createElement("div", null, "Hello ", this.props.name);
          }
        })
      }
    }
    stub_const 'Foo', Class.new(React::NativeLibrary)
    Foo.class_eval do
      imports "NativeLibrary"
      rename "NativeComponent" => "Bar"
    end
    expect(Foo::Bar)
      .to render_static_html('<div>Hello There</div>').with_params(name: "There")
  end

  xit "will give a reasonable error when failing to import a renamed component" do
    # TODO needs work
    %x{
      window.NativeLibrary = {
        NativeComponent: React.createClass({
          displayName: "HelloMessage",
          render: function render() {
            return React.createElement("div", null, "Hello ", this.props.name);
          }
        })
      }
    }
    stub_const 'Foo', Class.new(React::NativeLibrary)
    expect do
      Foo.class_eval do
        imports "NativeLibrary"
        rename "MispelledComponent" => "Bar"
      end
    end.to raise_error(/could not import MispelledComponent/)
  end

  xit "will import a single React.js component into the ruby name space" do
    # TODO needs work
    %x{
      window.NativeComponent = React.createClass({
        displayName: "HelloMessage",
        render: function render() {
          return React.createElement("div", null, "Hello ", this.props.name);
        }
      })
    }
    stub_const 'Foo', Class.new(React::Component::Base)
    Foo.class_eval do
      imports "NativeComponent"
    end
    expect(Foo)
      .to render_static_html('<div>Hello There</div>').with_params(name: "There")

  end

  xit "will import a name scoped React.js component into the ruby name space" do
    # TODO needs work
    %x{
      window.NativeLibrary = {
        NativeComponent: React.createClass({
          displayName: "HelloMessage",
          render: function render() {
            return React.createElement("div", null, "Hello ", this.props.name);
          }
        })
      }
    }
    stub_const 'Foo', Class.new(React::Component::Base)
    Foo.class_eval do
      imports "NativeLibrary.NativeComponent"
    end
    expect(Foo)
      .to render_static_html('<div>Hello There</div>').with_params(name: "There")

  end

  xit "will give a meaningful error if the React.js component is invalid" do
    %x{
      window.NativeObject = {}
    }
    stub_const 'Foo', Class.new(React::Component::Base)
    expect do
      Foo.class_eval do
        imports "NativeObject"
      end
    end.to raise_error("Foo cannot import 'NativeObject': does not appear to be a native react component.")
    expect do
      Foo.class_eval do
        imports "window.Baz"
      end
    end.to raise_error(/^Foo cannot import \'window\.Baz\'\: (?!does not appear to be a native react component)..*$/)
  end

  xit "allows passing native object as props" do
    %x{
      window.NativeComponent = React.createClass({
        displayName: "HelloMessage",
        render: function render() {
          return React.createElement("div", null, "Hello ", this.props.user.name);
        }
      })
    }
    stub_const 'Foo', Class.new(React::Component::Base)
    Foo.class_eval do
      imports "NativeComponent"
    end
    stub_const 'Wrapper', Class.new(React::Component::Base)
    Wrapper.class_eval do
      def render
        Foo(user: `{name: 'David'}`)
      end
    end
    expect(Wrapper).to render_static_html('<div>Hello David</div>')
  end

  context "automatic importing" do

    xit "will automatically import a React.js component when referenced in another component" do
      %x{
        window.NativeComponent = React.createClass({
          displayName: "HelloMessage",
          render: function render() {
            return React.createElement("div", null, "Hello ", this.props.name);
          }
        })
      }
      expect(React::Server.render_to_static_markup(
        React.create_element(NativeLibraryTestModule::Component, time_stamp: Time.now))).to match(/<div>Hello There.*<\/div>/)
    end

    xit "will automatically import a React.js component when referenced in another component" do
      stub_const 'Foo', Class.new(React::Component::Base)
      Foo.class_eval do
        render { NativeComponent(name: "There") }
      end
      %x{
        window.NativeComponent = React.createClass({
          displayName: "HelloMessage",
          render: function render() {
            return React.createElement("div", null, "Hello ", this.props.name);
          }
        })
      }
      expect(Foo).to render_static_html('<div>Hello There</div>')
    end

    xit "will automatically import a React.js component when referenced as a constant" do
      %x{
        window.NativeComponent = React.createClass({
          displayName: "HelloMessage",
          render: function render() {
            return React.createElement("div", null, "Hello ", this.props.name);
          }
        })
      }
      expect(NativeComponent)
        .to render_static_html('<div>Hello There</div>').with_params(name: "There")
    end

    xit "will automatically import a native library containing a React.js component" do
      %x{
        window.NativeLibrary = {
          NativeNestedLibrary: {
            NativeComponent: React.createClass({
              displayName: "HelloMessage",
              render: function render() {
                return React.createElement("div", null, "Hello ", this.props.name);
              }
            })
          }
        }
      }

      expect(React::Server.render_to_static_markup(
        React.create_element(NativeLibraryTestModule::NestedComponent, time_stamp: Time.now))).to match(/<div>Hello There.*<\/div>/)
    end

    xit "the library and components can begin with lower case letters" do
      %x{
        window.nativeLibrary = {
          nativeComponent: React.createClass({
            displayName: "HelloMessage",
            render: function render() {
              return React.createElement("div", null, "Hello ", this.props.name);
            }
          })
        }
      }
      expect(NativeLibrary::NativeComponent)
        .to render_static_html('<div>Hello There</div>').with_params(name: "There")
    end

    xit "will produce a sensible error if the component is not in the library" do
      %x{
        window.NativeLibrary = {
          NativeNestedLibrary: {
          }
        }
      }
      expect do
        React::Server.render_to_static_markup(React.create_element(NativeLibraryTestModule::NestedComponent, time_stamp: Time.now))
      end.to raise_error("could not import a react component named: NativeLibrary.NativeNestedLibrary.NativeComponent")
      
    end

  end
end
