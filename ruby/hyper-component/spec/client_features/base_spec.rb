require 'spec_helper'

describe 'Hyperloop::Component', js: true do

  before :each do
    on_client do
      class Foo < HyperComponent
        before_mount do
          @_instance_data = ["working"]
        end
        render do
          @_instance_data.first
        end
      end
    end
  end

  it 'can create a simple component class' do
    mount 'Foo'
    expect(page.body[-50..-19]).to match(/<span>working<\/span>/)
    binding.pry
  end

  it 'can create a simple component class that can be inherited to create another component class' do
    mount 'Bar' do
      class Bar < Foo
        before_mount do
          @_instance_data << "well"
        end
        render do
          @_instance_data.join(" ")
        end
      end
    end
    expect(page.body[-50..-19]).to match(/<span>working well<\/span>/)
  end

  it "can create an inherited component's  insert_element alias" do
    mount 'Tester' do
      module Container
        class Base < Foo
        end
        class Thing < Base
          before_mount { @_instance_data << "well"}
          render { @_instance_data.join(' ') }
        end
      end
      class Tester < HyperComponent
        render { Container::Thing() }
      end
    end
    expect(page).to have_content('working well')
  end
end
