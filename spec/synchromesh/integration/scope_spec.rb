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
        def scope(name, *args, &block)
          if args[0].respond_to? :call
            proc = args[0]
          else
            proc = args[1]
          end
          self.class.class_eval do
            attr_reader "#{name}_count".to_sym
          end
          instance_variable_set("@#{name}_count", 0)
          wrapped_proc = lambda do |*args|
            instance_variable_set("@#{name}_count", send("#{name}_count")+1); proc.call(*args, &block)
          end
          if args[0].respond_to? :call
            args[0] = wrapped_proc
          else
            args[1] = wrapped_proc
          end
          pretest_scope name, *args, &block
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
  end

  it "will be updated only when needed" do
    isomorphic do
      TestModel.class_eval do
        scope :scope1, lambda { where(completed: true) }
        scope :scope2, lambda { where(completed: true) }
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
    m1.update_attribute(:completed, false)
    page.should have_content('rendered 8 times')
    page.should have_content('scope1 count = 1')
    page.should have_content('scope2 count = 1')
    page.should have_content('model 3')
    TestModel.scope1_count.should eq(7)
    TestModel.scope2_count.should eq(5)
  end

  it "can have params" do
    isomorphic do
      TestModel.class_eval do
        scope :with_args, lambda { |match, match2| where(test_attribute: match) }
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
        scope :scope1, lambda { where(completed: true) }
        scope :with_args, lambda { |match| where(test_attribute: match) }
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
        scope :joined, [ChildModel], lambda { joins(:child_models).where("child_attribute = 'WHAAA'") }
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

  it 'can have a joins array as the third scope param' do
    isomorphic do
      TestModel.class_eval do
        scope :joined, lambda { joins(:child_models).where("child_attribute = 'WHAAA'") }, [ChildModel]
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
        scope(:quick, lambda { where(completed: true) }) do |record|
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
        scope(:quicker, lambda { where(completed: true) }) do |record, collection|
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
        scope(:quickest, lambda { where(completed: true) }) do |record, collection|
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
        scope :has_children, [ChildModel],
              lambda { joins(:child_models).distinct } do |record|
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
    parent = FactoryGirl.build(:test_model)
    parent.child_models << (child = FactoryGirl.create(:child_model))
    parent.save
    page.should have_content('.count = 1')
    child.update_attribute(:child_attribute, 'WHAAA')
    page.should have_content('.count = 1')
    child2 = FactoryGirl.create(:child_model, test_model: parent )
    page.should have_content('.count = 1')
    p2 = FactoryGirl.create(:test_model)
    page.should have_content('.count = 1')
    FactoryGirl.create(:child_model, test_model: p2)
    page.should have_content('.count = 2')
    p2.destroy
    page.should have_content('.count = 1')
    child.test_model = nil
    child.save
    page.should have_content('.count = 1')
    child2.destroy
    page.should have_content('.count = 0')
    TestModel.has_children_count.should eq(7)
  end


  it 'an empty joins array (or some symbol) will pass all changes to the block (if there is a block)' do
    isomorphic do
      TestModel.class_eval do
        scope :has_children, [],
              lambda { joins(:child_models).distinct } do |record|
          if record.is_a?(ChildModel)
            (record.test_model && record.destroyed?) || record.previous_changes[:test_model_id]
          else
            record.destroyed?
          end
        end
        scope(:do_it_all_the_time, :always_sync, lambda { all }) { true }
        scope :never_sync_it, :never_sync, lambda { all }
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
    parent = FactoryGirl.build(:test_model)
    parent.child_models << (child = FactoryGirl.create(:child_model))
    parent.save
    page.should have_content('.count = 1')
    child.update_attribute(:child_attribute, 'WHAAA')
    page.should have_content('.count = 1')
    child2 = FactoryGirl.create(:child_model, test_model: parent )
    page.should have_content('.count = 1')
    p2 = FactoryGirl.create(:test_model)
    page.should have_content('.count = 1')
    FactoryGirl.create(:child_model, test_model: p2)
    page.should have_content('.count = 2')
    p2.destroy
    page.should have_content('.count = 1')
    child.test_model = nil
    child.save
    page.should have_content('.count = 1')
    child2.destroy
    page.should have_content('.count = 0')
    TestModel.has_children_count.should eq(7)
    TestModel.do_it_all_the_time_count.should eq(9)
    TestModel.never_sync_it_count.should eq(1)
  end

  it 'with no joins array only the model being scoped will be passed to the block' do
    isomorphic do
      TestModel.class_eval do
        scope :has_children,
              lambda { joins(:child_models).distinct } do |record|
          true
        end
      end
    end
    mount 'TestComponent2' do
      class TestComponent2 < React::Component::Base
        render { "TestModel.has_children.count = #{TestModel.has_children.count}" }
      end
    end
    parent = FactoryGirl.build(:test_model)
    parent.child_models << (child = FactoryGirl.create(:child_model))
    parent.save
    page.should have_content('.count = 1')
    child.update_attribute(:child_attribute, 'WHAAA')
    page.should have_content('.count = 1')
    child2 = FactoryGirl.create(:child_model, test_model: parent )
    page.should have_content('.count = 1')
    p2 = FactoryGirl.create(:test_model)
    page.should have_content('.count = 1')
    FactoryGirl.create(:child_model, test_model: p2)
    page.should have_content('.count = 1')
    parent.save
    page.should have_content('.count = 2')
    p2.destroy
    page.should have_content('.count = 1')
    child.test_model = nil
    child.save
    page.should have_content('.count = 1')
    child2.destroy
    page.should have_content('.count = 1')
    parent.save
    page.should have_content('.count = 0')
    TestModel.has_children_count.should eq(6)
  end
end
