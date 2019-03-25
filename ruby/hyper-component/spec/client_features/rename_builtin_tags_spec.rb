require 'spec_helper'

describe 'redefining builtin tags', js: true do
  it "built in tags can be redefined" do
    mount 'Foo' do
      Hyperstack::Internal::Component::Tags.remove_method :DIV
      Hyperstack::Internal::Component::Tags.send(:remove_const, :DIV)

      class Hyperstack::Internal::Component::Tags::DIV #< Hyperloop::Component
        include Hyperstack::Component
        others :opts
        render do
          # see https://github.com/hyperstack-org/hyperstack/issues/47
          Hyperstack::Internal::Component::RenderingContext.render(:div, @Opts, data: {render_time:  Time.now}, &children)
        end
      end

      class Foo
        include Hyperstack::Component
        render(DIV, id: :tp) do
          "hello"
        end
      end
    end
    expect(Time.parse(find('#tp')['data-render-time'])).to be <= Time.now
    expect(page).to have_content('hello')
  end
end
