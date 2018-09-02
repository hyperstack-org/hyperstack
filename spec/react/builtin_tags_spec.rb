require 'spec_helper'

describe 'redefining builtin tags', js: true do
  it "built in tags can be redefined" do
    mount 'Foo' do
      React::Component::Tags.remove_method :DIV
      React::Component::Tags.send(:remove_const, :DIV)

      class React::Component::Tags::DIV < Hyperloop::Component
        others :opts
        render do
          present :div, params.opts, data: {render_time:  Time.now}, &children
        end
      end

      class Foo < Hyperloop::Component
        render(DIV, id: :tp) do
          "hello"
        end
      end
    end
    expect(Time.parse(find('#tp')['data-render-time'])).to be <= Time.now
    expect(page).to have_content('hello')
  end
end
