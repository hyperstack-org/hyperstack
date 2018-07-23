require 'spec_helper'

describe 'Builtin Tags', js: true do
  it "built in tags render method can be redefined" do
    mount 'Foo' do
      class React::Component::Tags::DIV < Hyperloop::Component
        render do
          params.opts['data-render-time'] = Time.now
          present "div", params.opts, &children
        end
      end
      class Foo < Hyperloop::Component
        render(DIV, id: :tp) do
          "hello"
        end
      end
    end
    expect(Time.parse(find('#tp')['data-render-time'])).to be <= Time.now
  end

  it "built in tags other callbacks can be added" do
    mount 'Foo' do
      class React::Component::Tags::DIV < Hyperloop::Component
        def add_time
          params.opts['data-render-time'] = Time.now
        end
        before_mount :add_time
        before_update :add_time
      end
      class Foo < Hyperloop::Component
        render(DIV, id: :tp) do
          "hello"
        end
      end
    end
    expect(Time.parse(find('#tp')['data-render-time'])).to be <= Time.now
  end
end
