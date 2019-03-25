require 'spec_helper'

describe 'An Example from the react.rb doc', js: true do
  it 'produces the correct result' do
    mount 'HelloMessage' do
      class HelloMessage
        include Hyperstack::Component
        render do
          DIV { "Hello World!" }
        end
      end
    end
    expect(page).to have_xpath('//div', text: 'Hello World!')
  end
end

describe 'Adding state to a component (second tutorial example)', js: true do
  before :each do
    on_client do
      class HelloMessage2
        include Hyperstack::Component
        before_mount { @user_name = '@catmando' }
        render do
          DIV { "Hello #{@user_name}" }
        end
      end
    end
  end

  it "produces the correct result" do
    mount 'HelloMessage2'
    expect(page).to have_xpath('//div', text: 'Hello @catmando')
  end

  it 'renders to the document' do
    evaluate_ruby do
      ele = JS.call(:eval, "document.body.appendChild(document.createElement('div'))")
      Hyperstack::Component::ReactAPI.render(Hyperstack::Component::ReactAPI.create_element(HelloMessage2), ele)
    end
    expect(page).to have_xpath('//div', text: 'Hello @catmando')
  end
end
