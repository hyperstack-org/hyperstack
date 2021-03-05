require 'spec_helper'

describe 'getting ref from an Element', js: true do
  it 'the ref method will return the mounted component instance' do
    mount 'TestComponent' do
      class AnotherComponent < HyperComponent
        render(DIV) { "another component"}
      end
      class TestComponent < HyperComponent
        after_mount { raise "Failed" unless @another_component.ref.is_a? AnotherComponent }
        render do
          @another_component = AnotherComponent()
        end
      end
    end
    expect(page).to have_content('another component')
  end

  it 'the ref method has a dom_node method that works with native dom nodes' do
    mount 'TestComponent' do
      class TestComponent < HyperComponent
        after_mount { raise "Failed" unless jQ[@another_component].html == 'my sweet div' }
        render do
          @another_component = DIV { 'my sweet div' }
        end
      end
    end
    expect(page).to have_content('my sweet div')
  end

  it 'the ref method has a dom_node method that works with application components' do
    mount 'TestComponent' do
      class AnotherComponent < HyperComponent
        render(DIV) { "another component"}
      end
      class TestComponent < HyperComponent
        after_mount { raise 'Failure' unless jQ[@another_component].html == 'another component' }
        render do
          @another_component = AnotherComponent()
        end
      end
    end
    expect(page).to have_content('another component')
  end

  it "the ref method has a dom_node method that works with native react components" do
    mount 'TestComponent' do
      JS.call(:eval,
        <<-JSCODE
          window.NativeComponent = class extends React.Component {
            constructor(props) {
              super(props);
              this.displayName = "aNativeComponent";
            }
            render() { return React.createElement("div", null, "a native component"); }
          }
        JSCODE
      )
      class AnotherComponent < Hyperloop::Component
        imports "NativeComponent"
      end
      class TestComponent < HyperComponent
        after_mount { raise 'Failure' unless jQ[@another_component].html == 'a native component' }
        render do
          @another_component = AnotherComponent()
        end
      end
    end
    expect(page).to have_content('a native component')
  end

  it 'the ref method has a dom_node method that works with application components' do
    mount 'TestComponent' do
      class AnotherComponent < HyperComponent
        other :others
        render(DIV) { "another component named #{@Others[:foo]}"}
      end
      class TestComponent < HyperComponent
        render do
          @ref_1 = AnotherComponent().as_node
          @ref_2 = @ref_1.render(foo: :bar)
        end
      end
    end
    expect(page).to have_content('another component named bar')
  end

end
