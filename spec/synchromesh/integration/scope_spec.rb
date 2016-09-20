require 'spec_helper'
require 'synchromesh/integration/test_components'

describe "synchronized scopes", js: true do

  before(:all) do
    require 'pusher'
    require 'pusher-fake'
    Pusher.app_id = "MY_TEST_ID"
    Pusher.key =    "MY_TEST_KEY"
    Pusher.secret = "MY_TEST_SECRET"
    require "pusher-fake/support/base"

    Synchromesh.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = "synchromesh"
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
    end
  end

  before(:all) do
    TestModel.class_eval do
      class << self
        alias pretest_scope scope
        def scope(name, proc, opts = {}, &block)
          self.class.class_eval do
            attr_reader "#{name}_count".to_sym
          end
          instance_variable_set("@#{name}_count", 0)
          patched_proc = lambda do |*args|
            instance_variable_set("@#{name}_count", send("#{name}_count")+1); proc.call(*args, &block)
          end
          pretest_scope name, patched_proc, opts, &block
        end
      end
    end
  end

  before(:each) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
    end
    size_window(:small, :portrait)
  end

  it "will be updated only when needed" do
    isomorphic do
      TestModel.class_eval do
        scope :scope1, -> { where(completed: true) }
        scope :scope2, -> { where(completed: true) }
      end
    end
    mount "TestComponent2" do
      class TestComponent2 < React::Component::Base
        before_mount do
          @render_count = 1
        end
        before_update do
          @render_count = @render_count + 1
        end
        render(:div) do
          div { "rendered #{@render_count} times"}
          div { "scope1 count = #{TestModel.scope1.count}" }
          div { "scope2 count = #{TestModel.scope2.count}"} if TestModel.scope1.count < 2
          TestModel.scope1.each do |model|
            div { model.test_attribute }
          end
        end
      end
    end
    page.should have_content('rendered 2 times')
    page.should have_content('scope1 count = 0')
    page.should have_content('scope2 count = 0')
    TestModel.scope1_count.should eq(2)  # once for scope1.count and once for scope1.each { .test_attribute }
    TestModel.scope2_count.should eq(1)
    m1 = FactoryGirl.create(:test_model, test_attribute: "model 1", completed: true)
    page.should have_content('rendered 3 times')
    page.should have_content('scope1 count = 1')
    page.should have_content('scope2 count = 1')
    page.should have_content('model 1')
    TestModel.scope1_count.should eq(3)
    TestModel.scope2_count.should eq(2)
    m2 = FactoryGirl.create(:test_model, test_attribute: "model 2", completed: false)
    page.should have_content('rendered 4 times')
    page.should have_content('scope1 count = 1')
    page.should have_content('scope2 count = 1')
    page.should have_content('model 1')
    TestModel.scope1_count.should eq(4)
    TestModel.scope2_count.should eq(3)
    FactoryGirl.create(:test_model, test_attribute: "model 3", completed: true)
    page.should have_content('rendered 5 times')
    page.should have_content('scope1 count = 2')
    page.should_not have_content('scope2', wait: 0)
    page.should have_content('model 1')
    page.should have_content('model 3')
    TestModel.scope1_count.should eq(5)
    TestModel.scope2_count.should eq(4)
    m2.update_attribute(:completed, true)
    page.should have_content('rendered 6 times')
    page.should have_content('scope1 count = 3')
    page.should have_content('model 1')
    page.should have_content('model 2')
    page.should have_content('model 3')
    TestModel.scope1_count.should eq(6)
    TestModel.scope2_count.should eq(4)  # will not change because nothing is viewing it
    m2.update_attribute(:completed, false)
    page.should have_content('rendered 7 times')
    TestModel.scope1_count.should eq(7)
    m1.update_attribute(:completed, false)
    page.should have_content('rendered 9 times')
    page.should have_content('scope1 count = 1')
    page.should have_content('scope2 count = 1')
    page.should have_content('model 3')
    TestModel.scope1_count.should eq(8)
    TestModel.scope2_count.should eq(5)
  end

  it "can have params" do
    isomorphic do
      TestModel.class_eval do
        scope :with_args, ->(match, match2) { where(test_attribute: match) }
      end
    end
    m1 = FactoryGirl.create(:test_model, test_attribute: "123")
    mount "TestComponent2", m: m1 do
      class TestComponent2 < React::Component::Base
        param :m, type: TestModel
        before_mount do
          @render_count = 1
        end
        before_update do
          @render_count = @render_count + 1
        end
        render(:div) do
          div { "rendered #{@render_count} times"}
          div { "with_args('match').count = #{TestModel.with_args(params.m.test_attribute, :foo).count}" }
        end
      end
    end
    m2 = FactoryGirl.create(:test_model)
    page.should have_content('.count = 1')
    m2.update_attribute(:test_attribute, m1.test_attribute)
    page.should have_content('.count = 2')
    m1.update_attribute(:test_attribute, '456')
    page.should have_content('.count = 1')
  end

  it "scopes with params can be nested" do
    isomorphic do
      TestModel.class_eval do
        scope :scope1, -> { where(completed: true) }
        scope :with_args, -> (match) { where(test_attribute: match) }
      end
    end
    mount "TestComponent2" do
      class TestComponent2 < React::Component::Base
        render(:div) do
          div { "scope1.scope2.count = #{TestModel.scope1.with_args(:foo).count}" }
        end
      end
    end
    page.should have_content('scope1.scope2.count = 0')
    FactoryGirl.create(:test_model, test_attribute: "foo", completed: true)
    page.should have_content('scope1.scope2.count = 1')
  end

  it 'can have a joins array' do
    isomorphic do
      TestModel.class_eval do
        scope :joined,
              -> { joins(:child_models).where("child_attribute = 'WHAAA'") },
              joins: ChildModel
      end
    end
    mount 'TestComponent2' do
      class TestComponent2 < React::Component::Base
        render { "TestModel.joined.count = #{TestModel.joined.count}" }
      end
    end
    parent = FactoryGirl.create(:test_model)
    child = FactoryGirl.create(:child_model, test_model: parent )
    page.should have_content('.count = 0')
    child.update_attribute(:child_attribute, 'WHAAA')
    page.should have_content('.count = 1')
  end

  it 'can have a block to dynamically test if scope needs updating' do
    isomorphic do
      TestModel.class_eval do
        scope :quick, -> { where(completed: true) }, sync: -> (record) do
          (record.completed && record.destroyed?) || record.previous_changes[:completed]
        end
      end
    end
    mount 'TestComponent2' do
      class TestComponent2 < React::Component::Base
        before_mount do
          @render_count = 1
        end
        before_update do
          @render_count = @render_count + 1
        end
        render(:div) do
          div { "rendered #{@render_count} times"}
          div { "quick.count = #{TestModel.quick.count}" }
        end
      end
    end
    m1 = FactoryGirl.create(:test_model)
    page.should have_content('.count = 0')
    page.should have_content('rendered 2 times')
    TestModel.quick_count.should eq(1)
    m1.update_attribute(:test_attribute, 'new_value')
    wait_for_ajax
    page.should have_content('.count = 0')
    page.should have_content('rendered 2 times')
    TestModel.quick_count.should eq(1)
    m1.update_attribute(:completed, true)
    page.should have_content('.count = 1')
    page.should have_content('rendered 3 times')
    TestModel.quick_count.should eq(2)
    m2 = FactoryGirl.create(:test_model, completed: true)
    page.should have_content('.count = 2')
    page.should have_content('rendered 4 times')
    TestModel.quick_count.should eq(3)
    m1.destroy
    page.should have_content('.count = 1')
    page.should have_content('rendered 5 times')
    TestModel.quick_count.should eq(4)
  end

  it 'can have a block to dynamically update the scope' do

    isomorphic do
      TestModel.class_eval do
        scope :quicker, -> { where(completed: true) }, sync: -> (record, collection) do
          if (record.completed && record.destroyed?) || (record.completed.nil? && record.previous_changes[:completed])
            ReactiveRecord.load do
              collection.all
            end.then do |collection_all|
              collection.delete(record)
            end
          elsif record.completed && record.previous_changes[:completed]
            ReactiveRecord.load do
              collection.all
            end.then do |collection_all|
              collection << record
            end
          end
          nil
        end
      end
    end

    mount 'TestComponent2' do
      class TestComponent2 < React::Component::Base
        before_mount do
          @render_count = 1
        end
        before_update do
          @render_count = @render_count + 1
        end
        render(:div) do
          div { "rendered #{@render_count} times"}
          div { "quicker.count = #{TestModel.quicker.count}" }
        end
      end
    end
    m1 = FactoryGirl.create(:test_model)
    page.should have_content('.count = 0')
    page.should have_content('rendered 2 times')
    TestModel.quicker_count.should eq(1)
    m1.update_attribute(:test_attribute, 'new_value')
    wait_for_ajax
    page.should have_content('.count = 0')
    page.should have_content('rendered 2 times')
    TestModel.quicker_count.should eq(1)
    m1.update_attribute(:completed, true)
    page.should have_content('.count = 1')
    page.should have_content('rendered 3 times')
    TestModel.quicker_count.should eq(2)
    m2 = FactoryGirl.create(:test_model, completed: true)
    page.should have_content('.count = 2')
    page.should have_content('rendered 4 times')
    TestModel.quicker_count.should eq(2)
    m1.destroy
    page.should have_content('.count = 1')
    page.should have_content('rendered 5 times')
    TestModel.quicker_count.should eq(2)
  end

  it 'can have a block to dynamically update the scope (2)' do

    isomorphic do
      TestModel.class_eval do
        scope :quickest, -> { where(completed: true) }, sync: -> (record, collection) do
          if (record.completed && record.destroyed?) || (record.completed.nil? && record.previous_changes[:completed])
            collection.delete(record)
          elsif record.completed && record.previous_changes[:completed]
            collection << record
          end
          nil
        end
      end
    end

    mount 'TestComponent2' do
      class TestComponent2 < React::Component::Base
        before_mount do
          @render_count = 1
        end
        before_update do
          @render_count = @render_count + 1
        end
        render(:div) do
          div { "rendered #{@render_count} times"}
          div { "quickest.count = #{TestModel.quickest.all.count}" }
        end
      end
    end
    m1 = FactoryGirl.create(:test_model)
    page.should have_content('.count = 0')
    page.should have_content('rendered 2 times')
    TestModel.quickest_count.should eq(1)
    m1.update_attribute(:test_attribute, 'new_value')
    wait_for_ajax
    page.should have_content('.count = 0')
    page.should have_content('rendered 2 times')
    TestModel.quickest_count.should eq(1)
    m1.update_attribute(:completed, true)
    page.should have_content('.count = 1')
    page.should have_content('rendered 3 times')
    TestModel.quickest_count.should eq(1)
    m2 = FactoryGirl.create(:test_model, completed: true)
    page.should have_content('.count = 2')
    page.should have_content('rendered 4 times')
    TestModel.quickest_count.should eq(1)
    m1.destroy
    page.should have_content('.count = 1')
    page.should have_content('rendered 5 times')
    TestModel.quickest_count.should eq(1)
  end

  it 'the joins array can be combined with the block' do
    isomorphic do
      TestModel.class_eval do
        scope :has_children,
              -> { joins(:child_models).distinct },
              joins: [ChildModel],
              sync: -> (record) do
          if record.is_a?(ChildModel)
            (record.test_model && record.destroyed?) || record.previous_changes[:test_model_id]
          else
            record.destroyed?
          end
        end
      end
    end
    mount 'TestComponent2' do
      class TestComponent2 < React::Component::Base
        render { "TestModel.has_children.count = #{TestModel.has_children.count}" }
      end
    end

    parent = FactoryGirl.create(:test_model) #h
      wait_for { TestModel.has_children_count }.to eq(1)
      page.should have_content('.count = 0')
    child = FactoryGirl.create(:child_model) #f
      wait_for { TestModel.has_children_count }.to eq(1)
      page.should have_content('.count = 0')
    child.update_attribute(:test_model, parent) #c
      wait_for { TestModel.has_children_count }.to eq(2)
      page.should have_content('.count = 1')
    child.update_attribute(:child_attribute, 'WHAAA') #d
      wait_for { TestModel.has_children_count }.to eq(2)
      page.should have_content('.count = 1')
    child.update_attribute(:test_model, nil) #e
      wait_for { TestModel.has_children_count }.to eq(3)
      page.should have_content('.count = 0')
    child.update_attribute(:test_model, parent) #c
      wait_for { TestModel.has_children_count }.to eq(3)
      page.should have_content('.count = 1')
    child.destroy #a/b
      wait_for { TestModel.has_children_count }.to eq(4)
      page.should have_content('.count = 0')
    parent.destroy #g
      wait_for { TestModel.has_children_count }.to eq(5)
      page.should have_content('.count = 0')
  end


  it 'the joins: :all option will join with all models' do
    isomorphic do
      TestModel.class_eval do
        scope :has_children,
              -> { joins(:child_models).distinct },
              joins: :all,
              sync: -> (record) do
          if record.is_a?(ChildModel)
            (record.test_model && record.destroyed?) || record.previous_changes[:test_model_id]
          else
            record.destroyed?
          end
        end
        scope :do_it_all_the_time, -> { all }, joins: :all, sync: -> { puts "&&&&&&&&&&&&& doitall the time &&&&&&"; true }
        scope :never_sync_it, -> { all }, sync: false
      end
    end
    mount 'TestComponent2' do
      class TestComponent2 < React::Component::Base
        render do
          TestModel.do_it_all_the_time.count
          TestModel.never_sync_it.count
          "TestModel.has_children.count = #{TestModel.has_children.count}"
        end
      end
    end
      #puts "*************** test 1 *********************"
      TestModel.has_children_count.should eq(1)
      TestModel.do_it_all_the_time_count.should eq(1)
      TestModel.never_sync_it_count.should eq(1)

    parent = FactoryGirl.create(:test_model) # need to save parent first to avoid
    # race condition when both child and parent get saved at the same time.
    # The timing of the pushed events from the server will result in either 1 or 2
    # fetches of the 'do_it_all_the_time_count' scope.
    # Final test in this example does it the normal way.
    wait_for { TestModel.do_it_all_the_time_count }.to eq(2)
    child = FactoryGirl.create(:child_model)
    wait_for { TestModel.do_it_all_the_time_count }.to eq(3)
    parent.child_models << child

      #puts "*************** test 2 *********************"
      page.should have_content('.count = 1')
      TestModel.has_children_count.should eq(2)
      wait_for { TestModel.do_it_all_the_time_count }.to eq(4)
      TestModel.never_sync_it_count.should eq(1)

      #puts "about to update the attribute now"

    child.update_attribute(:child_attribute, 'WHAAA')

      #puts "*************** test 3 *********************"
      page.should have_content('.count = 1')
      TestModel.has_children_count.should eq(2)
      wait_for { TestModel.do_it_all_the_time_count }.to eq(5)
      TestModel.never_sync_it_count.should eq(1)


    child2 = FactoryGirl.create(:child_model, test_model: parent )

      page.should have_content('.count = 1')
      wait_for { TestModel.has_children_count }.to eq(3)
      wait_for { TestModel.do_it_all_the_time_count }.to eq(6)
      TestModel.never_sync_it_count.should eq(1)

    p2 = FactoryGirl.create(:test_model)

      page.should have_content('.count = 1')
      TestModel.has_children_count.should eq(3)
      wait_for { TestModel.do_it_all_the_time_count }.to eq(7)
      TestModel.never_sync_it_count.should eq(1)

    FactoryGirl.create(:child_model, test_model: p2)

      page.should have_content('.count = 2')
      wait_for { TestModel.has_children_count }.to eq(4)
      wait_for { TestModel.do_it_all_the_time_count }.to eq(8)
      TestModel.never_sync_it_count.should eq(1)

    p2.destroy

      page.should have_content('.count = 1')
      wait_for { TestModel.has_children_count }.to eq(5)
      wait_for { TestModel.do_it_all_the_time_count }.to eq(9)
      TestModel.never_sync_it_count.should eq(1)

    child.test_model = nil
    child.save

      page.should have_content('.count = 1')
      wait_for { TestModel.has_children_count }.to eq(6)
      wait_for { TestModel.do_it_all_the_time_count }.to eq(10)
      TestModel.never_sync_it_count.should eq(1)

    child2.destroy

      page.should have_content('.count = 0')
      TestModel.has_children_count.should eq(7)
      wait_for { TestModel.do_it_all_the_time_count }.to eq(11)
      TestModel.never_sync_it_count.should eq(1)

    parent = FactoryGirl.build(:test_model)
    parent.child_models << (child = FactoryGirl.create(:child_model))
    parent.save

      page.should have_content('.count = 1')

  end

  it 'with no joins array only the model being scoped will be passed to the block' do
    isomorphic do
      TestModel.class_eval do
        scope :has_children,
              -> { joins(:child_models).distinct },
              sync: -> () { true }
      end
    end
    mount 'TestComponent2' do
      class TestComponent2 < React::Component::Base
        render { "TestModel.has_children.count = #{TestModel.has_children.count}" }
      end
    end
    #puts "************************** starting ******************************"
    parent = FactoryGirl.build(:test_model)
    parent.child_models << (child = FactoryGirl.create(:child_model))
    parent.save
    #puts "************************** test 1 ******************************"
    page.should have_content('.count = 1')
    child.update_attribute(:child_attribute, 'WHAAA')
    #puts "************************** test 2 ******************************"
    page.should have_content('.count = 1')
    child2 = FactoryGirl.create(:child_model, test_model: parent )
    #puts "************************** test 3 ******************************"
    page.should have_content('.count = 1')
    p2 = FactoryGirl.create(:test_model)  # this save will cause the scope to be recalcuated!
    # because even though this record does not have a child, some other record does!!!
    #puts "************************** test 4 ******************************"
    wait_for {TestModel.has_children_count}.to eq(3)
    page.should have_content('.count = 1')
    FactoryGirl.create(:child_model, test_model: p2)
     # seems like we get into a deadlock if we dont' do this here
    #puts "************************** test 5 ******************************"
    page.should have_content('.count = 1')
    parent.update_attribute :test_attribute, 'hi'
    page.should have_content('.count = 2')
    p2.destroy
    page.should have_content('.count = 1')
    child.test_model = nil
    child.save
    page.should have_content('.count = 1')
    child2.destroy
    page.should have_content('.count = 1')
    parent.update_attribute :test_attribute, 'bye'
    page.should have_content('.count = 0')
    TestModel.has_children_count.should eq(6)
  end
end
