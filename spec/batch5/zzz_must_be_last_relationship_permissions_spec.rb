# Something about this spec can cause havoc on specs following.
# somehow in the following specs AR objects are getting created in two different classes
# so when you compare for example User.first.todos.first == Todos.first  they are NOT equal huh!
# I suspect that its to with the fact that we remove and reload the classes
# but I got as far as proving that you have to actually create a todoitem and an associated comment
# once you do that the tests after will fail on stmts like this expect(user.todo_items.to_a).to match_array([TodoItem.first])
# because the class of user.todo_items.class != TodoItems.first even though they look exactly the same!!!

require 'spec_helper'
require 'test_components'

describe "relationship permissions" do#, dont_override_default_scope_permissions: true do

  before(:all) do

    require 'pusher'
    require 'pusher-fake'
    Pusher.app_id = "MY_TEST_ID"
    Pusher.key =    "MY_TEST_KEY"
    Pusher.secret = "MY_TEST_SECRET"
    require "pusher-fake/support/base"

    Hyperloop.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = "synchromesh"
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
    end

  end

  before(:each) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      regulate_class_connection { self }
      #regulate_all_broadcasts { |policy| policy.send_all }
    end
    ApplicationController.acting_user = nil
    size_window(:small, :portrait)
  end

  before(:each) do
    ActiveRecord::Base.regulate_scope unscoped: nil
    ActiveRecord::Base.regulate_default_scope nil
  end

  after(:each) do
    ['ApplicationRecord', 'TodoItem', 'Comment'].each do |klass|
      Object.send(:remove_const, klass.to_sym) && load("#{klass.underscore}.rb") rescue nil
    end
    ApplicationController.acting_user = nil
  end

  context 'on the server side' do
    it 'ActiveRecord::Base with by default leave unscoped and all scopes in a dont care state' do
      expect { TodoItem.__secure_remote_access_to_all(nil).__secure_collection_check(nil) }
      .to raise_error(Hyperloop::AccessViolation)
    end

    it 'will allow access to scopes' do
      TodoItem.class_eval do
        regulate_scope :all
      end
      expect { TodoItem.__secure_remote_access_to_all(nil).__secure_collection_check(nil) }
      .not_to raise_error
    end

    it 'will deny access to scopes' do
      TodoItem.class_eval do
        regulate_scope(:all) { denied! }
      end
      expect { TodoItem.__secure_remote_access_to_all(nil) }
      .to raise_error(Hyperloop::AccessViolation)
    end

    it "will leave any scope in a don't care state" do
      TodoItem.class_eval do
        scope :test, -> () { all }
      end
      test_scope = TodoItem.__secure_remote_access_to_test(nil)
      expect { test_scope.__secure_collection_check(nil) }
      .to raise_error(Hyperloop::AccessViolation)
    end

    it 'will allow access to has_many relationships' do
      TodoItem.class_eval do
        regulate_relationship :comments
      end
      expect { TodoItem.new.__secure_remote_access_to_comments(nil).__secure_collection_check(nil) }
      .not_to raise_error
    end

    it 'will deny access to has_many relationships' do
      TodoItem.class_eval do
        regulate_relationship(:comments) { denied! }
      end
      expect { TodoItem.new.__secure_remote_access_to_comments(nil) }
      .to raise_error(Hyperloop::AccessViolation)
    end

    it "will leave the has_many relationship in a don't care state" do
      comments = TodoItem.new.__secure_remote_access_to_comments(nil)
      expect { comments.__secure_collection_check(nil) }
      .to raise_error(Hyperloop::AccessViolation)
    end

    it "will not implicitly override a super classes scope access permission" do
      ApplicationRecord.class_eval do
        regulate_scope :test
      end
      TodoItem.class_eval do
        scope :test, -> () { all }
      end
      expect { TodoItem.__secure_remote_access_to_test(nil).__secure_collection_check(nil) }
      .not_to raise_error
    end

    it "will pass any parameters along to the permission proc" do
      TodoItem.class_eval do
        regulate_scope(:find_string) { |s| denied! if s == 'doa'}
      end
      expect { TodoItem.__secure_remote_access_to_find_string(nil, 'doa') }
      .to raise_error(Hyperloop::AccessViolation)
    end

    it "finder methods have access to the acting_user methods" do
      TodoItem.class_eval do
        regulate_scope(:all) { acting_user }
      end
      expect { TodoItem.__secure_remote_access_to_all(nil).__secure_collection_check(nil) }
      .to raise_error(Hyperloop::AccessViolation)
      expect { TodoItem.__secure_remote_access_to_all(true).__secure_collection_check(nil) }
      .not_to raise_error
    end

    it "finder methods have access to the denied! methods" do
      TodoItem.class_eval do
        finder_method(:pow) { denied! }
      end
      expect { TodoItem.__secure_remote_access_to__pow(nil) }
      .to raise_error(Hyperloop::AccessViolation)
    end

    it "server methods have access to the acting_user" do
      TodoItem.class_eval do
        server_method(:pow) { acting_user }
      end
      expect(TodoItem.new.__secure_remote_access_to_pow('Omar'))
      .to eq('Omar')
    end

    it "server methods have access to the denied! method" do
      TodoItem.class_eval do
        server_method(:pow) { denied! }
      end
      expect { TodoItem.new.__secure_remote_access_to_pow('Omar') }
      .to raise_error(Hyperloop::AccessViolation)
    end

    it "can set the policy directly on the scope with a proc" do
      TodoItem.class_eval do
        scope :test, -> () { all }, regulate: -> () { acting_user }
      end
      expect { TodoItem.__secure_remote_access_to_test(true).__secure_collection_check(nil) }
      .not_to raise_error
      expect { TodoItem.__secure_remote_access_to_test(nil).__secure_collection_check(nil) }
      .to raise_error(Hyperloop::AccessViolation)
    end

    it 'can set the policy directly on the default scope method' do
      TodoItem.class_eval do
        default_scope -> () { all }, regulate: -> () { denied! if acting_user }
      end
      expect { TodoItem.__secure_remote_access_to_all(true) }
      .to raise_error(Hyperloop::AccessViolation)
      expect { TodoItem.__secure_remote_access_to_all(nil) }
      .not_to raise_error
    end

    it 'can set the policy for the default scope (all) using regulate_default_scope' do
      TodoItem.class_eval do
        regulate_default_scope { denied! if acting_user }
      end
      expect { TodoItem.__secure_remote_access_to_all(true) }
      .to raise_error(Hyperloop::AccessViolation)
      expect { TodoItem.__secure_remote_access_to_all(nil) }
      .not_to raise_error
    end

    it "can use 'regulate: truthy-value' to allow access directly on the scope" do
      TodoItem.class_eval do
        scope :test, -> () { all }, regulate: :always_allow
      end
      expect { TodoItem.__secure_remote_access_to_test(nil).__secure_collection_check(nil) }
      .not_to raise_error
    end

    it "can treat 'regulate: falsy-value' as don't care if directly on the scope" do
      TodoItem.class_eval do
        scope :test, -> () { all }, regulate: nil
      end
      test_scope = TodoItem.__secure_remote_access_to_test(nil)
      expect { test_scope.__secure_collection_check(nil) }
      .to raise_error(Hyperloop::AccessViolation)
    end

    %i[denied! denied deny].each do |value|
      it "can use 'regulate: #{value}' to allow access directly on the scope" do
        TodoItem.class_eval do
          scope :test, -> () { all }, regulate: value
        end
        expect { TodoItem.__secure_remote_access_to_test(nil) }
        .to raise_error(Hyperloop::AccessViolation)
      end
    end

    it "can set the policy directly on the scope with a proc" do
      stub_const 'TodoItem', Class.new(ApplicationRecord)
      TodoItem.has_many :comments, regulate: -> () { acting_user }
      expect { TodoItem.new.__secure_remote_access_to_comments(true).__secure_collection_check(nil) }
      .not_to raise_error
      expect { TodoItem.new.__secure_remote_access_to_comments(nil).__secure_collection_check(nil) }
      .to raise_error(Hyperloop::AccessViolation)
    end

    it "can use 'regulate: truthy-value' to allow access directly on the scope" do
      stub_const 'TodoItem', Class.new(ApplicationRecord)
      TodoItem.has_many :comments, regulate: :always_allow
      expect { TodoItem.new.__secure_remote_access_to_comments(nil).__secure_collection_check(nil) }
      .not_to raise_error
    end

    it "can treat 'regulate: falsy-value' as don't care if directly on the scope" do
      stub_const 'TodoItem', Class.new(ApplicationRecord)
      TodoItem.has_many :comments, regulate: nil
      comments = TodoItem.new.__secure_remote_access_to_comments(nil)
      expect { comments.__secure_collection_check(nil) }
      .to raise_error(Hyperloop::AccessViolation)
    end

    %i[denied! denied deny].each do |value|
      it "can use 'regulate: #{value}' to allow access directly on the scope" do
        stub_const 'TodoItem', Class.new(ApplicationRecord)
        TodoItem.has_many :comments, regulate: value
        expect { TodoItem.new.__secure_remote_access_to_comments(nil) }
        .to raise_error(Hyperloop::AccessViolation)
      end
    end
  end
  context 'integration test', js: true do
    before(:each) do
      client_option raise_on_js_errors: :off
      ApplicationController.acting_user = User.new(first_name: 'fred')
    end
    context 'with synchromesh running' do
      before(:each) do
        TestApplicationPolicy.class_eval do
          regulate_all_broadcasts { |policy| policy.send_all }
        end
      end
      it 'will allow access via scopes' do
        isomorphic do
          TodoItem.scope :test_scope, ->() { all }, regulate: :always_allow
        end
        TodoItem.create
        mount 'TestComponentZ' do
          class TestComponentZ < Hyperloop::Component
            render do
              DIV { "There is #{TodoItem.test_scope.count} TodoItem" }
            end
          end
        end
        expect(page).to have_content("There is 1 TodoItem")
        TodoItem.create
        expect(page).to have_content("There is 2 TodoItem")
      end

      it 'will allow access via relationships' do
        isomorphic do
          TodoItem.regulate_relationship comments: true
        end
        todo_item = TodoItem.create
        Comment.create(todo_item: todo_item)
        mount 'TestComponentZ' do
          class TestComponentZ < Hyperloop::Component
            render do
              DIV { "There is #{TodoItem.find(1).comments.count} comments on the first TodoItem" }
            end
          end
        end
        expect(page).to have_content("There is 1 comments on the first TodoItem")
        Comment.create(todo_item: todo_item)
        expect(page).to have_content("There is 2 comments on the first TodoItem")
      end

      it 'will protect access via scopes' do
        isomorphic do
          TodoItem.scope :test_scope, -> () { all } # no regulation implies "don't know"
        end
        2.times { TodoItem.create }
        mount 'TestComponentZ' do
          class TestComponentZ < Hyperloop::Component
            render do
              DIV { "There is #{TodoItem.test_scope.count} TodoItem" }
            end
          end
        end
        expect(page).to have_content("There is 1 TodoItem") # should be 2 but will never update
        TodoItem.create
        wait_for_ajax
        expect(page).to have_content("There is 1 TodoItem")  # it will never change because scope is not allowed
      end

      it 'will protect access via relationships' do
        todo_item = TodoItem.create
        2.times { Comment.create(todo_item: todo_item) }
        mount 'TestComponentZ' do
          class TestComponentZ < Hyperloop::Component
            render do
              DIV { "There is #{TodoItem.find(1).comments.count} comments on the first TodoItem" }
            end
          end
        end
        wait_for_ajax
        expect(page).to have_content("There is 1 comments on the first TodoItem") # should be 2 but will never update
        # unlike scopes relationships generally will increment automatically on the client if the attributes are being
        # broadcast.  I.e. hyperloop client will see that a new comment is pointing to the curren todo and will add
        # it the collection on the client.
      end
    end
    context 'without synchromesh running' do
      before(:each) do
        isomorphic do
          TodoItem.class_eval do
            scope :test_scope1, -> () { all }, regulate: -> () {  acting_user }
            scope :test_scope2, -> () { all }, regulate: -> () { !acting_user }
            server_method(:pow) { denied! unless user == acting_user; acting_user.first_name }
            TodoItem.regulate_relationship(:comments) { acting_user == user }
          end
        end
        mount 'DummyComponent' do
          class DummyComponent < Hyperloop::Component
            render(DIV) { 'hello' }
          end
          module ReactiveRecord
            class Base
              class << self
                attr_accessor :last_log_message
                def log(*args)
                  Base.last_log_message = args
                end
              end
            end
          end
        end
      end
      it 'will control access via relationships' do
        todo_item1 = TodoItem.create(user: ApplicationController.acting_user)
        todo_item2 = TodoItem.create(user: nil)

        Comment.create(todo_item: todo_item1)
        Comment.create(todo_item: todo_item1)

        expect_promise("ReactiveRecord.load { TodoItem.find(#{todo_item1.id}).comments.count }").to eq(2)
        expect_promise("ReactiveRecord.load { TodoItem.find(#{todo_item2.id}).comments.count }").not_to eq(0)
        expect_evaluate_ruby('ReactiveRecord::Base.last_log_message').to eq(['Fetch failed', 'error'])
      end
      it 'will control access via scope' do
        2.times { TodoItem.create }
        expect_promise("ReactiveRecord.load { TodoItem.test_scope1.count }").to eq(2)
        expect_promise("ReactiveRecord.load { TodoItem.test_scope2.count }").not_to eq(2)
        expect_evaluate_ruby('ReactiveRecord::Base.last_log_message').to eq(['Fetch failed', 'error'])
      end
      it 'will allow server_methods to control access' do
        todo_item1 = TodoItem.create(user: ApplicationController.acting_user)
        todo_item2 = TodoItem.create(user: User.create(first_name: 'fred'))
        expect_promise("ReactiveRecord.load { TodoItem.find(#{todo_item1.id}).pow }").to eq('fred')
        expect_promise("ReactiveRecord.load { TodoItem.find(#{todo_item2.id}).pow }").not_to eq('fred')
        expect_evaluate_ruby('ReactiveRecord::Base.last_log_message').to eq(['Fetch failed', 'error'])
      end
    end
  end
end
