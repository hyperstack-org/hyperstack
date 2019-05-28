require 'spec_helper'

describe 'The FreeRender module', js: true do
  it "doesnt need any stinkin render macro" do
    mount 'Foo' do
      class Foo
        include Hyperstack::Component
        include Hyperstack::Component::FreeRender
        DIV(class: :foo) do
          "hello"
        end
      end
    end
    expect(find('.foo')['innerHTML']).to eq('hello')
  end
end
