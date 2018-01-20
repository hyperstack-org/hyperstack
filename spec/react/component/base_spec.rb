require 'spec_helper'

describe 'React::Component::Base', js: true do

  before :each do
    on_client do
      class Foo < React::Component::Base
        before_mount do
          @instance_data = ["working"]
        end
        def render
          @instance_data.first
        end
      end
    end
  end

  it 'can create a simple component class' do
    mount 'Foo'
    expect(page.body[-50..-19]).to match(/<span>working<\/span>/)
  end

  it 'can create a simple component class that can be inherited to create another component class' do
    mount 'Bar' do
      class Bar < Foo
        before_mount do
          @instance_data << "well"
        end
        def render
          @instance_data.join(" ")
        end
      end
    end
    expect(page.body[-50..-19]).to match(/<span>working well<\/span>/)
  end
end
