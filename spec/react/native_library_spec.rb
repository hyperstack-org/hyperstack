require 'spec_helper'
require 'reactrb/auto-import'

if opal?

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

describe "React::NativeLibrary" do

  after(:each) do
    %x{
      delete window.NativeLibrary;
      delete window.NativeComponent;
      delete window.nativeLibrary;
      delete window.nativeComponent;
      delete window.NativeObject;
    }
    Object.send :remove_const, :NativeLibrary
    Object.send :remove_const, :NativeComponent
  end

  it "can use native_react_component? to detect a native React.js component" do
    %x{
      window.NativeComponent = React.createClass({
        displayName: "HelloMessage",
        render: function render() {
          return React.createElement("div", null, "Hello ", this.props.name);
        }
      })
    }
    expect(React::API.native_react_component?(`window.NativeComponent`)).to be_truthy
    expect(React::API.native_react_component?(`{render: function render() {}}`)).to be_falsy
    expect(React::API.native_react_component?(`window.DoesntExist`)).to be_falsy
    expect(React::API.native_react_component?(``)).to be_falsy
  end

  it "will import a React.js library into the Ruby name space" do
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
    end
    expect(React.render_to_static_markup(
      React.create_element(Foo::NativeComponent, name: "There"))).to eq('<div>Hello There</div>')
  end

  it "will rename an imported a React.js component" do
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
    expect(React.render_to_static_markup(
      React.create_element(Foo::Bar, name: "There"))).to eq('<div>Hello There</div>')
  end

  it "will give a reasonable error when failing to import a renamed component" do
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

  it "will import a single React.js component into the ruby name space" do
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
    expect(React.render_to_static_markup(
      React.create_element(Foo, name: "There"))).to eq('<div>Hello There</div>')

  end

  it "will import a name scoped React.js component into the ruby name space" do
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
    expect(React.render_to_static_markup(
      React.create_element(Foo, name: "There"))).to eq('<div>Hello There</div>')

  end

  it "will give a meaningful error if the React.js component is invalid" do
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

  context "automatic importing" do

    it "will automatically import a React.js component when referenced in another component" do
      %x{
        window.NativeComponent = React.createClass({
          displayName: "HelloMessage",
          render: function render() {
            return React.createElement("div", null, "Hello ", this.props.name);
          }
        })
      }
      expect(React.render_to_static_markup(
        React.create_element(NativeLibraryTestModule::Component, time_stamp: Time.now))).to match(/<div>Hello There.*<\/div>/)
    end

    it "will automatically import a React.js component when referenced in another component" do
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
      expect(React.render_to_static_markup(
        React.create_element(Foo))).to eq('<div>Hello There</div>')
    end

    it 'will automatically import a React.js component when referenced in another component with the _as_node suffix' do
      stub_const 'Foo', Class.new(React::Component::Base)
      Foo.class_eval do
        render(:div) do
          e = React::Element.new(NativeComponent_as_node(name: 'There'))
          2.times { e.render }
        end
      end
      %x{
        window.NativeComponent = React.createClass({
          displayName: "HelloMessage",
          render: function render() {
            return React.createElement("div", null, "Hello ", this.props.name);
          }
        })
      }
      expect(React.render_to_static_markup(
        React.create_element(Foo))).to eq('<div><div>Hello There</div><div>Hello There</div></div>')
    end

    it "will automatically import a React.js component in a library when referenced in another component with the _as_node suffix" do
      stub_const 'Foo', Class.new(React::Component::Base)
      Foo.class_eval do
        render(:div) do
          e = React::Element.new(NativeLibrary::NativeComponent_as_node(name: 'There'))
          2.times { e.render }
        end
      end
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
      expect(React.render_to_static_markup(
        React.create_element(Foo))).to eq('<div><div>Hello There</div><div>Hello There</div></div>')
    end

    it "will automatically import a React.js component when referenced as a constant" do
      %x{
        window.NativeComponent = React.createClass({
          displayName: "HelloMessage",
          render: function render() {
            return React.createElement("div", null, "Hello ", this.props.name);
          }
        })
      }
      expect(React.render_to_static_markup(
        React.create_element(NativeComponent, name: "There"))).to eq('<div>Hello There</div>')
    end

    it "will automatically import a native library containing a React.js component" do
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

      expect(React.render_to_static_markup(
        React.create_element(NativeLibraryTestModule::NestedComponent, time_stamp: Time.now))).to match(/<div>Hello There.*<\/div>/)
    end

    it "the library and components can begin with lower case letters" do
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
      expect(React.render_to_static_markup(
        React.create_element(NativeLibrary::NativeComponent, name: "There"))).to eq('<div>Hello There</div>')
    end

    it "will produce a sensible error if the component is not in the library" do
      %x{
        window.NativeLibrary = {
          NativeNestedLibrary: {
          }
        }
      }
      expect do
        React.render_to_static_markup(React.create_element(NativeLibraryTestModule::NestedComponent, time_stamp: Time.now))
      end.to raise_error("could not import a react component named: NativeLibrary.NativeNestedLibrary.NativeComponent")

    end

  end
end
end
