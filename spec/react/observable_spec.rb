require 'spec_helper'

if opal?

describe 'React::Observable' do
  it "allows to set value on Observable" do
    stub_const 'Zoo', Class.new {
      include React::Component
      param :foo, type: React::Observable
      before_mount do
        params.foo! 4
      end

      def render
        nil
      end
    }

    stub_const 'Foo', Class.new
    Foo.class_eval do
      include React::Component

      def render
        div do
          Zoo(foo: state.foo! )
          span { state.foo.to_s }
        end
      end
    end

    instance = React::Test::Utils.render_into_document(React.create_element(Foo))
    html = `#{instance.dom_node}.innerHTML`
    # data-reactid appear in earlier versions of reactjs
    %x{
        var REGEX_REMOVE_IDS = /\s?data-reactid="[^"]+"/g;
        html = html.replace(REGEX_REMOVE_IDS, '');
    }
    expect(html).to eq('<span></span><span>4</span>')
  end
end

end
