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
          opts = _synchromesh_scope_args_check(args)
          self.class.class_eval do
            attr_reader "#{name}_count".to_sym
          end
          instance_variable_set("@#{name}_count", 0)
          original_proc = opts[:server]
          opts[:server] = lambda do |*args|
            instance_variable_set("@#{name}_count", send("#{name}_count")+1); original_proc.call(*args, &block)
          end
          pretest_scope name, opts, &block
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

  it "can use the all scope" do
    mount "TestComponent2" do
      class TestComponent2 < React::Component::Base
        render do
          "count = #{TestModel.all.count}"
        end
      end
    end
    page.should have_content("count = 0")
    m = FactoryGirl.create(:test_model)
    page.should have_content("count = 1")
    m.destroy
    page.should have_content("count = 0")
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

  context 'basic joins' do

    it 'will not update a joined scope without a joins option' do
      isomorphic do
        TestModel.class_eval do
          scope :joined,
                -> { joins(:child_models).where("child_attribute = 'WHAAA'") }
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
      page.should have_content('.count = 0')
    end

    it 'can have a joins option' do
      isomorphic do
        TestModel.class_eval do
          scope :joined,
                -> { joins(:child_models).where("child_attribute = 'WHAAA'") },
                joins: 'child_models'
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
  end

  it 'can have a client filter method' do

    isomorphic do
      TestModel.class_eval do
        scope :quicker, -> { where(completed: true) }, client: -> { completed }
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
    TestModel.quicker_count.should eq(1)
    m2 = FactoryGirl.create(:test_model, completed: true)
    page.should have_content('.count = 2')
    page.should have_content('rendered 4 times')
    TestModel.quicker_count.should eq(1)
    m1.destroy
    page.should have_content('.count = 1')
    page.should have_content('rendered 5 times')
    TestModel.quicker_count.should eq(1)
  end

  it 'can have a client collector method' do

    isomorphic do
      TestModel.class_eval do
        def <=>(other); self.test_attribute <=> other.test_attribute; end
        scope :filter_and_sort, -> { where(completed: true).order('test_attribute ASC') },
              select: -> { select { |r| r.completed }.sort }
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
          div { "filter_and_sort.count = #{TestModel.filter_and_sort.count}" }
          if TestModel.filter_and_sort.any?
            div { "test attributes: #{TestModel.filter_and_sort.collect { |r| r.test_attribute }.join(', ')}" }
          else
            div { "no test attributes" }
          end
        end
      end
    end
    TestModel.filter_and_sort_count.should eq(2)
    m1 = FactoryGirl.create(:test_model)
    page.should have_content('.count = 0')
    page.should have_content('rendered 2 times')
    page.should have_content('no test attributes')
    TestModel.filter_and_sort_count.should eq(2)
    m1.update_attribute(:test_attribute, 'N')
    wait_for_ajax
    page.should have_content('.count = 0')
    page.should have_content('rendered 2 times')
    page.should have_content('no test attributes')
    TestModel.filter_and_sort_count.should eq(2)
    m1.update_attribute(:completed, true)
    page.should have_content('.count = 1')
    page.should have_content('rendered 3 times')
    page.should have_content('test attributes: N')
    TestModel.filter_and_sort_count.should eq(2)
    m2 = FactoryGirl.create(:test_model, test_attribute: 'A', completed: true)
    page.should have_content('.count = 2')
    page.should have_content('rendered 4 times')
    page.should have_content('test attributes: A, N')
    TestModel.filter_and_sort_count.should eq(2)
    m3 = FactoryGirl.create(:test_model, test_attribute: 'Z', completed: true)
    page.should have_content('.count = 3')
    page.should have_content('rendered 5 times')
    page.should have_content('test attributes: A, N, Z')
    TestModel.filter_and_sort_count.should eq(2)
    m1.destroy
    page.should have_content('.count = 2')
    page.should have_content('rendered 6 times')
    page.should have_content('test attributes: A, Z')
    TestModel.filter_and_sort_count.should eq(2)
    m3.update_attribute(:completed, false)
    page.should have_content('.count = 1')
    page.should have_content('rendered 7 times')
    page.should have_content('test attributes: A')
    TestModel.filter_and_sort_count.should eq(2)
  end

  it 'client side scoping methods can take args' do

    isomorphic do
      TestModel.class_eval do
        def to_s
          "<TestModel id: #{id} test_attribute: #{test_attribute}>"
        end
        def <=>(other)
          (test_attribute || '') <=> (other.test_attribute || '')
        end
        scope :matches, -> (s) { where(['test_attribute LIKE ?', "%#{s}%"])},
              client: -> (s) { puts "test_attribute =~ /#{s}/ is #{!!(test_attribute =~ /#{s}/)}"; test_attribute =~ /#{s}/ }
        scope :sorted, -> (dir) { order("test_attribute #{dir==:asc ? 'ASC' : 'DESC'}") },
              select: -> (dir) { sort { |a, b| dir == :asc ? a <=> b : b <=> a }.tap {|r| puts "sorted(#{dir==:asc}) as [#{r}]"} }
      end
    end

    mount 'TestComponent2' do
      class TestComponent2 < React::Component::Base
        export_state pat: :foo
        export_state dir: :asc
        before_mount do
          @render_count = 1
        end
        before_update do
          @render_count = @render_count + 1
        end
        def scoped
          puts "scoping: #{TestComponent2.pat}, #{TestComponent2.dir}"
          TestModel.matches(TestComponent2.pat).sorted(TestComponent2.dir)
        end
        render(:div) do
          div { "rendered #{@render_count} times"}
          div { "matches(#{TestComponent2.pat}).count = #{TestModel.matches(TestComponent2.pat).count}" }
          if scoped.any?
            div { "test attributes: #{scoped.collect { |r| r.test_attribute[0] }.join(', ')}" }
          else
            div { "no test attributes" }
          end
        end
      end
    end
    starting_fetch_time = evaluate_ruby("ReactiveRecord::Base.last_fetch_at")
    m1 = FactoryGirl.create(:test_model)
    page.should have_content('.count = 0')
    page.should have_content('rendered 2 times')
    page.should have_content('no test attributes')
    m1.update_attribute(:test_attribute, 'N')
    page.should have_content('rendered 2 times')
    page.should have_content('.count = 0')
    page.should have_content('no test attributes')
    m1.update_attribute(:test_attribute, 'N - foobar')
    page.should have_content('.count = 1')
    page.should have_content('rendered 3 times')
    page.should have_content('test attributes: N')
    m2 = FactoryGirl.create(:test_model, test_attribute: 'A - is a foo')
    page.should have_content('.count = 2')
    page.should have_content('rendered 4 times')
    page.should have_content('test attributes: A, N')
    m3 = FactoryGirl.create(:test_model, test_attribute: 'Z - is also a foo')
    page.should have_content('.count = 3')
    page.should have_content('rendered 5 times')
    page.should have_content('test attributes: A, N, Z')
    evaluate_ruby("ReactiveRecord::Base.last_fetch_at").should eq(starting_fetch_time)
    evaluate_ruby("TestComponent2.dir! :desc")
    page.should have_content('test attributes: Z, N, A')
    page.should have_content('rendered 7 times')
    starting_fetch_time = evaluate_ruby("ReactiveRecord::Base.last_fetch_at")
    m1.destroy
    page.should have_content('.count = 2')
    page.should have_content('rendered 8 times')
    page.should have_content('test attributes: Z, A')
    m3.update_attribute(:test_attribute, 'Z - is a bar')
    page.should have_content('.count = 1')
    page.should have_content('rendered 9 times')
    page.should have_content('test attributes: A')
    evaluate_ruby("ReactiveRecord::Base.last_fetch_at").should eq(starting_fetch_time)
    evaluate_ruby('TestComponent2.pat! :bar')
    page.should have_content('.count = 1')
    page.should have_content('test attributes: Z')
    page.should have_content('rendered 11 times')
    starting_fetch_time = evaluate_ruby("ReactiveRecord::Base.last_fetch_at")
    m2.update_attribute(:test_attribute, 'A is also a bar')
    page.should have_content('.count = 2')
    page.should have_content('rendered 12 times')
    page.should have_content('test attributes: Z, A')
    evaluate_ruby("ReactiveRecord::Base.last_fetch_at").should eq(starting_fetch_time)
  end

  it 'the joins array can be combined with the client proc' do
    isomorphic do
      TestModel.class_eval do
        scope :has_children,
              joins: 'child_models',
              server: -> { joins(:child_models).distinct },
              client: -> { child_models.count > 0 }
      end
    end
    mount 'TestComponent2' do
      class TestComponent2 < React::Component::Base
        render { "TestModel.has_children.count = #{TestModel.has_children.count}" }
      end
    end
    TestModel.has_children_count.should eq(1)
    parent = FactoryGirl.create(:test_model)
    page.should have_content('.count = 0')
    child = FactoryGirl.create(:child_model)
    page.should have_content('.count = 0')
    child.update_attribute(:test_model, parent)
    page.should have_content('.count = 1')
    child.update_attribute(:child_attribute, 'WHAAA')
    page.should have_content('.count = 1')
    child.update_attribute(:test_model, nil)
    page.should have_content('.count = 0')
    child.update_attribute(:test_model, parent)
    page.should have_content('.count = 1')
    child.destroy
    page.should have_content('.count = 0')
    parent.destroy
    page.should have_content('.count = 0')
    TestModel.has_children_count.should eq(1)
  end

  it 'the joins option can join with all or no models' do
    isomorphic do
      TestModel.class_eval do
        scope :has_children_joins_all,
              joins: :all,
              server: -> { joins(:child_models).distinct }
        scope :has_children_no_joins,
              joins: [],
              server: -> { joins(:child_models).distinct }
      end
    end
    mount 'TestComponent2' do
      class TestComponent2 < React::Component::Base
        render(DIV) do
          DIV { "TestModel.has_children_joins_all.count = #{TestModel.has_children_joins_all.count}" }
          DIV { "TestModel.has_children_no_joins.count = #{TestModel.has_children_no_joins.count}" }
        end
      end
    end
    TestModel.has_children_joins_all_count.should eq(1)
    TestModel.has_children_no_joins_count.should eq(1)
    parent = FactoryGirl.create(:test_model)
    wait_for_ajax
    TestModel.has_children_no_joins_count.should eq(1)
    wait_for { TestModel.has_children_joins_all_count }.to eq(2)
    child = FactoryGirl.create(:child_model)
    wait_for { TestModel.has_children_joins_all_count }.to eq(3)
    parent.child_models << child
    wait_for { TestModel.has_children_joins_all_count }.to eq(4)
    TestModel.has_children_no_joins_count.should eq(1)
    page.should have_content('all.count = 1')
    page.should have_content('joins.count = 0')
    parent.update_attribute(:test_attribute, 'hello')
    page.should have_content('joins.count = 0')
    TestModel.has_children_no_joins_count.should eq(1)
  end

  it 'server side scopes can be procs returning arrays of elements' do
    isomorphic do
      TestModel.class_eval do
        scope :rev,
              server: -> { all.reverse }
      end
    end
    mount 'TestComponent2' do
      class TestComponent2 < React::Component::Base
        render do
          "test attributes: #{TestModel.rev.collect { |r| r.test_attribute }.join(', ')}"
        end
      end
    end
    FactoryGirl.create(:test_model, test_attribute: 1)
    page.should have_content('test attributes: 1')
    FactoryGirl.create(:test_model, test_attribute: 2)
    page.should have_content('test attributes: 2, 1')
  end

  it 'can force reload using the ! suffix' do
    isomorphic do
      TestModel.class_eval do
        scope :rev,
              joins: [],
              server: -> { all.reverse }
      end
    end
    mount 'TestComponent2' do

      class TestComponent2 < React::Component::Base
        before_mount do
          @reverse_collection = []
        end
        render do
          if @current_count != TestModel.all.count # this forces a rerender...
            puts "asking for reverse collection"
            @reverse_collection = TestModel.rev!
            @current_count = TestModel.all.count
          end
          puts "rendering #{@reverse_collection}"
          "test attributes: #{@reverse_collection.collect { |r| r.test_attribute }.join(', ')}"
        end
      end
    end
    FactoryGirl.create(:test_model, test_attribute: 1)
    page.should have_content('test attributes: 1')
    FactoryGirl.create(:test_model, test_attribute: 2)
    page.should have_content('test attributes: 2, 1')
  end

end
