require 'spec_helper'

describe 'React::State', js: true do
  it "can create dynamically initialized exported states" do
    expect_evaluate_ruby do
      class Foo
        include Hyperstack::Component
        include Hyperstack::State::Observable
        class << self
          state_accessor :foo
        end
        Hyperstack::Application::Boot.on_dispatch { @foo = :bar }
      end
      Hyperstack::Application::Boot.run
      Foo.foo
    end.to eq('bar')
  end

  it 'ignores state updates during rendering' do
    client_option render_on: :both
    evaluate_ruby do
      class StateTest < Hyperloop::Component
        include Hyperstack::State::Observable
        class << self
          state_accessor :boom
        end
        before_mount do
          # force boom to be on the observing list during the current rendering cycle
          mutate StateTest.boom = !StateTest.boom
          # this is automatically called by after_mount / after_update, but we don't want
          # to have to setup a complicated async test, so we just force it now.
          # if we don't do this, then updating boom will have no effect on the first render
          update_objects_to_observe
        end
        render do
          (StateTest.boom ? "Boom" : "No Boom").tap { mutate StateTest.boom = !StateTest.boom }
        end
      end
      MARKUP = Hyperstack::Component::Server.render_to_static_markup(Hyperstack::Component::ReactAPI.create_element(StateTest))
    end
    expect_evaluate_ruby("MARKUP").to eq('<span>Boom</span>')
    expect_evaluate_ruby("StateTest.boom").to be_falsy
    expect(page.driver.browser.manage.logs.get(:browser).reject { |entry|
      entry_s = entry.to_s
      entry_s.include?("Deprecated feature") ||
      entry_s.include?("Mount() on the server. This is a no-op.") ||
      entry_s.include?('Object freezing is not supported by Opal')
    }.size).to eq(0)
  end
end
