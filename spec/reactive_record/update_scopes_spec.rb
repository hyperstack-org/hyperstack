require 'spec_helper'
require 'synchromesh/integration/test_components'
require 'reactive_record/factory'
require 'rspec-steps'

RSpec::Steps.steps "updating scopes", js: true do

  before(:all) do
    seed_database
  end

  before(:step) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    size_window(:small, :portrait)
  end

  it "will update .all and rerender after saving a record" do
    mount "TestComponent" do
      class TestComponent < React::Component::Base
        def render
          #div do
            "TodoItem.count = #{TodoItem.all.count}".span
            #ul { TodoItem.each { |todo| li { todo.id.to_s } }}
          #end
        end
      end
    end
    starting_count = TodoItem.count
    expect(page).to have_content("TodoItem.count = #{starting_count}")
    evaluate_ruby { TodoItem.new(title: "play it again sam").save }
    expect(page).to have_content("TodoItem.count = #{starting_count+1}")
  end

  it "destroying records causes a rerender" do
    count = TodoItem.count
    while count > 0
      expect(page).to have_content("TodoItem.count = #{count}")
      evaluate_ruby do
        ReactiveRecord.load { TodoItem.last.itself }.then { |todo| todo.destroy }
      end
      count -= 1
    end
    expect(page).to have_content("TodoItem.count = 0")
  end

  end
