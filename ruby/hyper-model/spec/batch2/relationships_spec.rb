require 'spec_helper'
require 'test_components'

describe "synchronizing relationships", js: true do

  before(:all) do
    require 'pusher'
    require 'pusher-fake'
    Pusher.app_id = "MY_TEST_ID"
    Pusher.key =    "MY_TEST_KEY"
    Pusher.secret = "MY_TEST_SECRET"
    require "pusher-fake/support/base"

    Hyperstack.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = "synchromesh"
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
    end
  end

  before(:each) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    size_window(:small, :portrait)
  end

  it "belongs_to with count" do
    parent = FactoryBot.create(:test_model)
    mount "TestComponent2", model: parent do
      class TestComponent2 < HyperComponent
        param :model, type: TestModel
        render(DIV) do
          puts "RENDERING! #{@Model.child_models.count} items"
          DIV { "#{@Model.child_models.count} items" }
          #ul { model.child_models.each { |model| li { model.child_attribute }}}
        end
      end
    end

    page.should have_content("0 items")
    FactoryBot.create(:child_model, test_model: parent, child_attribute: "first child")
    page.should have_content("1 items")
    parent.child_models << FactoryBot.create(:child_model, child_attribute: "second child")
    page.should have_content("2 items")
    parent.child_models.first.destroy
    page.should have_content("1 items")
  end

  it "belongs_to without the associated record" do
    parent = FactoryBot.create(:test_model)
    mount "TestComponent2" do
      class TestComponent2 < HyperComponent
        render(DIV) do
          DIV { "#{ChildModel.count} items" }
          UL { ChildModel.each { |model| LI { model.child_attribute }}}
        end
      end
    end
    page.should have_content("0 items")
    FactoryBot.create(:child_model, test_model: parent, child_attribute: "first child")
    page.should have_content("1 items")
    parent.child_models << FactoryBot.create(:child_model, child_attribute: "second child")
    page.should have_content("2 items")
    parent.child_models.first.destroy
    page.should have_content("1 items")
  end

  it "adding child to a new model on client" do
    mount "TestComponent2" do
      class TestComponent2 < HyperComponent
        before_mount do
          @parent = TestModel.new
          @child = ChildModel.new
        end
        after_mount do
          after(0) do # simulate external event updating system
            @parent.child_models << @child
            @parent.save
          end
        end
        render(DIV) do
          "parent has #{@parent.child_models.count} children"
        end
      end
    end
    page.should have_content("parent has 1 children", wait: 1)
    expect(TestModel.first.child_models.count).to eq(1)
  end

  it "adding child to a new model on client after render" do
    # Hyperstack.configuration do |config|
    #   #config.transport = :none
    # end
    m = FactoryBot.create(:test_model)
    m.child_models << FactoryBot.create(:child_model)
    mount "TestComponent2" do
      class TestComponent2 < HyperComponent
        def self.parent
          @parent ||= TestModel.find(1)
        end
        def self.add_child
          parent.child_models << ChildModel.new
          parent.save
        end
        render(DIV) do
          "parent has #{TestComponent2.parent.child_models.count} children".tap { |s| puts s}
        end
      end
    end
    wait_for_ajax
    expect(TestModel.first.child_models.count).to eq(1)
    m.child_models << FactoryBot.create(:child_model)
    evaluate_ruby("TestComponent2.add_child")
    page.should have_content("parent has 3 children")
  end

  it "preserves the order of children" do
    isomorphic do
      ChildModel.class_eval do
        server_method :do_some_calc do
          child_attribute
        end
      end
      TestModel.class_eval do
        server_method :do_some_calc do
          child_models.collect(&:child_attribute).join(', ')
        end
      end
    end
    expect_promise do
      parent = TestModel.new
      4.times do |i|
        parent.child_models << ChildModel.new(child_attribute: i.to_s)
      end
      ReactiveRecord.load do
        parent.do_some_calc.tap { parent.child_models[3].do_some_calc }
      end
    end.to eq('0, 1, 2, 3')
  end

  it "will re-render the count after an item is added or removed from a model" do
    m1 = FactoryBot.create(:test_model)
    mount "TestComponent2" do
      class TestComponent2 < HyperComponent
        render(DIV) do
          "Count of TestModel: #{TestModel.count}".span
        end
      end
    end
    page.should have_content("Count of TestModel: 1")
    m2 = FactoryBot.create(:test_model)
    page.should have_content("Count of TestModel: 2")
    m1.destroy
    page.should have_content("Count of TestModel: 1")
    m2.destroy
    page.should have_content("Count of TestModel: 0")
  end

  it "will re-render the model's all scope after an item is added or removed" do
    m1 = FactoryBot.create(:test_model)
    mount "TestComponent2" do
      class TestComponent2 < HyperComponent
        render(DIV) do
          puts "Count of TestModel: #{TestModel.collect { |i| i.id}.length}"
          "Count of TestModel: #{TestModel.collect { |i| i.id}.length}".span
        end
      end
    end
    page.should have_content("Count of TestModel: 1")
    m2 = FactoryBot.create(:test_model)
    page.should have_content("Count of TestModel: 2")
    m1.destroy
    page.should have_content("Count of TestModel: 1")
    m2.destroy
    page.should have_content("Count of TestModel: 0")
  end

  context "updating a client scoped method when applied to a collection" do

    before(:each) do

      isomorphic do
        ChildModel.class_eval do
          scope :boo_ha, -> { all }, client: -> { true }
        end
      end

      m = FactoryBot.create(:test_model, test_attribute: 'hello')
      FactoryBot.create(:child_model, test_model: m)

      mount "TestComponent3" do
        class TestComponent3 < HyperComponent
          render(OL) do
            TestModel.all[0].child_models.boo_ha.each do |child|
              LI { "child id = #{child.id} "}
            end
          end
        end
      end
      page.should have_content('child id = 1')
    end

    it "will update when sent from the server" do
      ChildModel.create(child_attribute: :foo, test_model: TestModel.find(1))
      page.should have_content('child id = 2')
      ChildModel.find(1).destroy
      sleep 0.1 # necessary for chrome driver to work with pusher faker
      page.should_not have_content('child id = 1', wait: 2)
    end

    it "will update when sent from the client" do
      evaluate_ruby do
        # ReactiveRecord::Collection.hypertrace instrument: :all
        # ReactiveRecord::Collection.hypertrace :class, instrument: :all
        # ReactiveRecord::Base.hypertrace instrument: :sync_unscoped_collection!
        # ReactiveRecord::ScopeDescription.hypertrace instrument: :all

        ChildModel.create(child_attribute: :foo, test_model: TestModel.find(1))
      end
      page.should have_content('child id = 2')
      evaluate_ruby do
        ChildModel.find(1).destroy
      end
      sleep 0.1 # necessary for chrome driver to work with pusher faker
      page.should_not have_content('child id = 1', wait: 2)
    end

  end

  context "updating a has_many relationship" do

    before(:each) do

      m = FactoryBot.create(:test_model, test_attribute: 'hello')
      FactoryBot.create(:child_model, test_model: m)

      mount "TestComponent3" do
        class InnerComponent < HyperComponent
          param :child
          render { LI { "child id = #{@Child.id} #{@Child.test_model.test_attribute}"} }
        end
        class TestComponent3 < HyperComponent
          render(OL) do
            TestModel.all[0].child_models.each do |child|
              InnerComponent(child: child)
            end
          end
        end
      end
      page.should have_content('child id = 1')
    end

    it "will update when sent from the server" do
      ChildModel.create(child_attribute: :foo, test_model: TestModel.find(1))
      page.should have_content('child id = 2')
      ChildModel.find(1).destroy
      sleep 0.1 # necessary for chrome driver to work with pusher faker
      page.should_not have_content('child id = 1', wait: 2)
      page.should have_content('child id = 2')
    end

    it "will update when sent from the client" do

      evaluate_ruby do
        ChildModel.create(child_attribute: :foo, test_model: TestModel.find(1))
      end
      page.should have_content('child id = 2')
      evaluate_ruby do
        # ReactiveRecord::Collection.hypertrace instrument: :all
        # ReactiveRecord::Collection.hypertrace :class, instrument: :all
        # ReactiveRecord::Base.hypertrace instrument: :sync_unscoped_collection!
        # ReactiveRecord::ScopeDescription.hypertrace instrument: :all

        ChildModel.find(1).destroy
      end
      sleep 0.1 # necessary for chrome driver to work with pusher faker
      page.should_not have_content('child id = 1', wait: 2)
    end

  end

  it "causes a rerender when an association is updated" do
    FactoryBot.create(:test_model, test_attribute: 'hello')
    mount "TestComponent4" do
      class TestComponent4 < HyperComponent
        class << self
          attr_accessor :child_model
          def update_relationship
            Hyperstack::Model.load do
              TestModel.first
            end.then do |test_model|
              child_model.test_model = test_model
            end
          end
        end
        before_mount { TestComponent4.child_model = ChildModel.new(child_attribute: 'hello') }
        render { DIV { TestComponent4.child_model.test_model&.test_attribute } }
      end
    end
    evaluate_ruby do
      TestComponent4.update_relationship
    end
    page.should have_content(TestModel.first.test_attribute)
  end

  it "composed_of"

end
