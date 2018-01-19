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
  end

  describe "functional stateless component (supported in reactjs v14+ only)" do
    it "is detected as native React.js component by `native_react_component?`" do
      expect_evaluate_ruby do
        React::API.native_react_component?(JS.call(:eval, "(function () { return function C () { return null; }; })();"))
      end.to be_truthy
    end

    it "imports a React.js functional stateless component" do        
      mount 'Foo', name: "There" do
        JS.call(:eval, 'window.NativeLibrary = { FunctionalComponent: function HelloMessage(props){
          return React.createElement("div", null, "Hello ", props.name); }}')
        class Foo < React::Component::Base
          imports "NativeLibrary.FunctionalComponent"
        end
      end
      expect(page.body[-60..-19]).to include('<div>Hello There</div>')
    end
  end

  it "can use native_react_component? to detect a native React.js component" do
    evaluate_ruby do
      "this makes sure React is loaded for this test, before js is run"
    end
    page.execute_script('window.NativeComponent = class extends React.Component {
      constructor(props) {
        super(props);
        this.displayName = "HelloMessage";
      }
      render() { return React.createElement("div", null, "Hello ", this.props.name); }
    }')
    expect_evaluate_ruby do
      React::API.native_react_component?(JS.call(:eval, '(function(){ return window.NativeComponent; })();'))
    end.to be_truthy
    expect_evaluate_ruby do
      React::API.native_react_component?(JS.call(:eval, '(function(){ return {render: function render() {}}; })();'))
    end.to be_falsy
    expect_evaluate_ruby do
      React::API.native_react_component?(JS.call(:eval, '(function(){ return window.DoesntExist; })();'))
    end.to be_falsy
    expect_evaluate_ruby do
      React::API.native_react_component?()
    end.to be_falsy
  end

  it "will import a React.js library into the Ruby name space" do
    mount 'Foo::NativeComponent', name: "There" do
      JS.call(:eval,
        <<-JSCODE
          window.NativeLibrary = {
            NativeComponent: class extends React.Component {
            constructor(props) {
              super(props);
              this.displayName = "HelloMessage";
            }
            render() { return React.createElement("div", null, "Hello ", this.props.name); }
          }}
        JSCODE
      )
      class Foo < React::NativeLibrary
        imports "NativeLibrary"
      end
    end
    expect(page.body[-60..-19]).to include('<div>Hello There</div>')
  end

  it "will import a nested React.js library into the Ruby name space" do
    mount 'Foo::NestedLibrary::NativeComponent', name: "There" do
      JS.call(:eval,
        <<-JSCODE
          window.NativeLibrary = {
            NestedLibrary: {
              NativeComponent: class extends React.Component {
                constructor(props) {
                  super(props);
                  this.displayName = "HelloMessage";
                }
                render() { return React.createElement("div", null, "Hello ", this.props.name); }
            }}}
        JSCODE
      )
      class Foo < React::NativeLibrary
        imports "NativeLibrary"
      end
    end
    expect(page.body[-60..-19]).to include('<div>Hello There</div>')
  end

  it "will rename an imported a React.js component" do
    mount 'Foo::Bar', name: "There" do
      JS.call(:eval,
      <<-JSCODE
        window.NativeLibrary = {
          NativeComponent: class extends React.Component {
            constructor(props) {
              super(props);
              this.displayName = "HelloMessage";
            }
            render() { return React.createElement("div", null, "Hello ", this.props.name); }
          }}
        JSCODE
      )
      class Foo < React::NativeLibrary
        imports "NativeLibrary"
        rename "NativeComponent" => "Bar"
      end
    end
    expect(page.body[-60..-19]).to include('<div>Hello There</div>')
  end

  it "will give a reasonable error when failing to import a renamed component" do
    client_option raise_on_js_errors: :off
    mount 'Foo' do
      JS.call(:eval,
        <<-JSCODE
          window.NativeLibrary = {
            NativeComponent: class extends React.Component {
              constructor(props) {
                super(props);
                this.displayName = "HelloMessage";
              }
              render() { return React.createElement("div", null, "Hello ", this.props.name); }
            }}
        JSCODE
      )
      class Foo < React::NativeLibrary
        imports "NativeLibrary"
        rename "MispelledComponent" => "Bar"
      end
    end
    expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
      .to match(/NativeLibrary.MispelledComponent is undefined/)
      # TODO was testing for cannot import, but that message gets trunkated
  end

  it "will import a single React.js component into the ruby name space" do
    mount 'Foo', name: "There" do
      JS.call(:eval,
        <<-JSCODE
          window.NativeComponent = class extends React.Component {
            constructor(props) {
              super(props);
              this.displayName = "HelloMessage";
            }
            render() { return React.createElement("div", null, "Hello ", this.props.name); }
          }
        JSCODE
      )
      class Foo < React::Component::Base
        imports "NativeComponent"
      end
    end
    expect(page.body[-60..-19]).to include('<div>Hello There</div>')
  end

  it "will import a name scoped React.js component into the ruby name space" do
    mount 'Foo', name: "There" do
      JS.call(:eval,
        <<-JSCODE
          window.NativeLibrary = {
            NativeComponent: class extends React.Component {
              constructor(props) {
                super(props);
                this.displayName = "HelloMessage";
              }
              render() { return React.createElement("div", null, "Hello ", this.props.name); }
            }}
        JSCODE
      )
      class Foo < React::Component::Base
        imports "NativeLibrary.NativeComponent"
      end
    end
    expect(page.body[-60..-19]).to include('<div>Hello There</div>')
  end

  it "will give a meaningful error if the React.js component is invalid" do
    client_option raise_on_js_errors: :off
    evaluate_ruby do
      JS.call(:eval, "window.NativeObject = {}")
      class Foo < React::Component::Base; end
    end
    expect_evaluate_ruby do
      begin
        Foo.class_eval do
          imports "NativeObject"
        end
      rescue Exception => e
        e.message
      end
    end.to match(/Foo cannot import 'NativeObject': does not appear to be a native react component./)
    expect_evaluate_ruby do
      begin
        Foo.class_eval do
          imports "window.Baz"
        end
      rescue Exception => e
        e.message
      end
    end.to match(/Foo cannot import \'window\.Baz\'\: (?!does not appear to be a native react component)./)
  end

  it "allows passing native object as props" do
    mount 'Wrapper' do
      JS.call(:eval,
        <<-JSCODE
          window.NativeComponent = class extends React.Component {
            constructor(props) {
              super(props);
              this.displayName = "HelloMessage";
            }
            render() { return React.createElement("div", null, "Hello " + this.props.user.name); }
          }
        JSCODE
      )
      class Foo < React::Component::Base
        imports "NativeComponent"
      end
      class Wrapper < React::Component::Base
        def render
          Foo(user: JS.call(:eval, "(function () { return {name: 'David'}; })();"))
        end
      end
    end
    expect(page.body[-60..-19]).to include('<div>Hello David</div>')
  end

  context "automatic importing" do

    it "will automatically import a React.js component when referenced in another component" do
      evaluate_ruby do
        JS.call(:eval,
          <<-JSCODE
            window.NativeComponent = class extends React.Component {
              constructor(props) {
                super(props);
                this.displayName = "HelloMessage";
              }
              render() { return React.createElement("div", null, "Hello ", this.props.name); }
            }
          JSCODE
        )
        React::Test::Utils.render_component_into_document(NativeLibraryTestModule::Component, time_stamp: Time.now)
      end
      expect(page.body[-100..-19]).to match(/<div>Hello There.*<\/div>/)
    end

    it "will automatically import a React.js component when referenced in another component in a different way" do
      mount 'Foo' do
        class Foo < React::Component::Base
          render { NativeComponent(name: "There") }
        end
        JS.call(:eval,
          <<-JSCODE
            window.NativeComponent = class extends React.Component {
              constructor(props) {
                super(props);
                this.displayName = "HelloMessage";
              }
              render() { return React.createElement("div", null, "Hello ", this.props.name); }
            }
          JSCODE
        )
      end
      expect(page.body[-50..-19]).to match('<div>Hello There</div>')
    end

    it "will automatically import a React.js component when referenced as a constant" do
      mount 'NativeComponent', name: "There" do
        JS.call(:eval,
          <<-JSCODE
            window.NativeComponent = class extends React.Component {
              constructor(props) {
                super(props);
                this.displayName = "HelloMessage";
              }
              render() { return React.createElement("div", null, "Hello ", this.props.name); }
            }
          JSCODE
        )
      end
      expect(page.body[-50..-19]).to match('<div>Hello There</div>')
    end

    it "will automatically import a native library containing a React.js component" do
      evaluate_ruby do
        JS.call(:eval,
          <<-JSCODE
            window.NativeLibrary = {
              NativeNestedLibrary: {
                NativeComponent: class extends React.Component {
                  constructor(props) {
                    super(props);
                    this.displayName = "HelloMessage";
                  }
                  render() { return React.createElement("div", null, "Hello ", this.props.name); }
              }}}
          JSCODE
        )
        React::Test::Utils.render_component_into_document(NativeLibraryTestModule::NestedComponent, time_stamp: Time.now)
      end
      expect(page.body[-100..-19]).to match(/<div>Hello There.*<\/div>/)
    end

    it "the library and components can begin with lower case letters" do
      mount 'NativeLibrary::NativeComponent', name: "There" do
        JS.call(:eval,
          <<-JSCODE
            window.nativeLibrary = {
              nativeComponent: class extends React.Component {
                constructor(props) {
                  super(props);
                  this.displayName = "HelloMessage";
                }
                render() { return React.createElement("div", null, "Hello ", this.props.name); }
            }}
          JSCODE
        )
      end
      expect(page.body[-50..-19]).to match('<div>Hello There</div>')
    end

    it "will produce a sensible error if the component is not in the library" do
      client_option raise_on_js_errors: :off
      expect_evaluate_ruby do
        JS.call(:eval,
          <<-JSCODE
            window.NativeLibrary = {
              NativeNestedLibrary: { }
            }
          JSCODE
        )
        begin
          React::Test::Utils.render_component_into_document(NativeLibraryTestModule::NestedComponent, time_stamp: Time.now)
        rescue Exception => e
          e.message
        end
      end.to match(/could not import a react component named: NativeLibrary.NativeNestedLibrary.NativeComponent/)
    end

    it "a NativeLibrary::NestedLibrary::NativeComponent() call will not resolve to a toplevel module NativeComponent (was a bug)" do
      evaluate_ruby do
        module NativeComponent; end
        JS.call(:eval,
          <<-JSCODE
            window.NativeLibrary = {
              NativeNestedLibrary: {
                NativeComponent: class extends React.Component {
                  constructor(props) {
                    super(props);
                    this.displayName = "HelloMessage";
                  }
                  render() { return React.createElement("div", null, "Hello ", this.props.name); }
              }}}
          JSCODE
        )
        class Foo < React::NativeLibrary
          def render
            NativeLibrary::NativeNestedLibrary::NativeComponent(name: 'Worksmaker')
          end
        end
        React::Test::Utils.render_component_into_document(Foo)
      end
      expect(page.body[-80..-19]).to match(/<div>Hello Worksmaker<\/div>/)
    end
  end
end
