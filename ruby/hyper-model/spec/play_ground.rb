require 'spec_helper'

describe "playground", js: true do

  it "works!" do
    mount "SuperTest::Derp" do
      module SuperTest
      end

      SuperTest.const_set :Derp, Class.new(React::Component::Base)
      SuperTest::Derp.class_eval do
      	inherited(self)
      	def render
      		p {"hi"}
      	end
      end
      SuperTest::Derp.hypertrace instrument: :all
    end
    page.should have_content('hi')
    pause
  end

  it "works! as well" do

    mount "SuperTest::Derp" do
      module SuperTest
      end

      # YOU HAVE TO have the parens otherwise ruby rules say that
      # the block will be sent to const_set (where it is ignored)

      SuperTest.const_set(:Derp, Class.new(React::Component::Base) do
        inherited(self)
        def render
          p {"hi"}
        end
      end)
      SuperTest::Derp.hypertrace instrument: :all
    end
    page.should have_content('hi')
    pause
  end

  it "works!?" do

    mount "SuperTest::Derp" do
      module SuperTest
      end

      SuperTest.const_set(:Derp, Class.new do
        #include React::Component
        #inherited(self)
        def render
          p {"hi"}
        end
      end)
      SuperTest::Derp.hypertrace instrument: :all
    end
    pause
    page.should have_content('hi')
    pause
  end

end
