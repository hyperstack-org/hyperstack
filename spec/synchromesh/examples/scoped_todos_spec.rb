require 'spec_helper'
require 'synchromesh/integration/test_components'

describe "example scopes", js: true do

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

  before(:each) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    isomorphic do
      Todo.class_eval do
      scope :with_managers_comments,
            -> { joins(owner: :manager, comments: :author).where('managers_users.id = authors_comments.id').distinct },
            joins: ['comments.author', 'owner'],
            client: -> { comments.detect { |comment| comment.author == owner.manager } }
      end
      Comment.class_eval do
        scope :by_manager,
              -> { joins(todo: { owner: :manager }).where('managers_users.id = author_id').distinct},
              joins: ['todo.owner.manager', 'author'],
              client: -> { todo.owner.manager == author }
      end
    end
    size_window(:small, :portrait)
  end

  it "runs the server side scopes okay" do
    expect(Todo.with_managers_comments).to be_empty
    expect(Comment.by_manager).to be_empty
    boss = FactoryGirl.create(:user, name: :boss)
    employee = FactoryGirl.create(:user, name: :fred, manager: boss)
    todo = FactoryGirl.create(:todo, owner: employee)
    comment = FactoryGirl.create(:comment, author: boss, todo: todo)
    FactoryGirl.create(:comment, author: employee, todo: todo)
    FactoryGirl.create(:comment, author: employee, todo: FactoryGirl.create(:todo, owner: employee))
    expect(Todo.with_managers_comments).to match_array [todo]
    expect(Comment.by_manager).to match_array [comment]
  end

  it "a complex client side scope" do

    mount "TestComponent3" do
      class UserTodos < React::Component::Base
        render(DIV) do
          div { "todos by user with comments" }
          User.each do |user|
            DIV do
              DIV { "#{user.name}'s Todos'" }
              UL do
                user.assigned_todos.each do |todo|
                  LI do
                    todo.title.span
                    UL do
                      todo.comments.by_manager.each do |comment|
                        LI { "MANAGER SAYS: #{comment.comment}" }
                      end
                    end unless todo.comments.by_manager.empty?
                  end; end; end; end; end; end; end
      class ManagerComments < React::Component::Base
        render(DIV) do
          puts "managers have made comments: #{!!Todo.with_managers_comments.any?}"
          if Todo.with_managers_comments.any?
            DIV { "managers comments" }
            UL do
              Todo.with_managers_comments.each do |todo|
                DIV do
                  "#{todo.owner.name} - #{todo.title}".span
                  UL do
                    todo.comments.each do |comment|
                      LI { "BOSS SAYS: #{comment.comment}" } if comment.author == todo.owner.manager
                    end; end; end; end; end
          else
            DIV { "no manager comments" }
          end; end; end
      class TestComponent3 < React::Component::Base
        def render
          puts "RENDERING TESTCOMPONENT3"
          div do
            UserTodos {}
            ManagerComments {}
          end; end; end; end
    starting_fetch_time = evaluate_ruby("ReactiveRecord::Base.last_fetch_at")
    #pause "about to add the boss"
    boss = FactoryGirl.create(:user, name: :boss)
    #pause "about to add the employee"
    employee = FactoryGirl.create(:user, name: :joe, manager: boss)
    #pause "about to add the todo"
    todo = FactoryGirl.create(:todo, title: "joe's todo", owner: employee)
    wait_for_ajax
    evaluate_ruby("ReactiveRecord::Base.last_fetch_at").should eq(starting_fetch_time)
    #pause "adding a comment from the boss"
    comment = FactoryGirl.create(:comment, comment: "The Boss Speaks", author: boss, todo: todo)
    page.should have_content('The Boss Speaks')
    #pause "added the boss speaks"
    fred = FactoryGirl.create(:user, role: :employee, name: :fred)
    #pause "fred added"
    fred.assigned_todos << FactoryGirl.create(:todo, title: 'fred todo')
    #pause "added another todo to fred"
    evaluate_ruby do
      mitch = User.new(name: :mitch)
      mitch.assigned_todos << Todo.new(title: 'mitch todo')
      mitch.save
    end
    wait_for_ajax
    #pause "mitch added"
    user1 = FactoryGirl.create(:user, role: :employee, name: :frank)
    user2 = FactoryGirl.create(:user, role: :employee, name: :bob)
    mgr   = FactoryGirl.create(:user, role: :manager, name: :sally)
    #pause "frank, bob, and sally added"
    user1.assigned_todos << FactoryGirl.create(:todo, title: 'frank todo 1')
    user1.assigned_todos << FactoryGirl.create(:todo, title: 'frank todo 2')
    user2.assigned_todos << FactoryGirl.create(:todo, title: 'bob todo 1')
    user2.assigned_todos << FactoryGirl.create(:todo, title: 'bob todo 2')
    user1.comments << FactoryGirl.create(:comment, comment: "frank made this comment", todo: user2.assigned_todos.first)
    user2.comments << FactoryGirl.create(:comment, comment: "bob made this comment", todo: user1.assigned_todos.first)
    # evaluate_ruby do
    #   Synchromesh::IncomingBroadcast.hypertrace do
    #     #instrument :merge_current_values
    #     break_on_exit?(:merge_current_values) { Todo.find(5).comments.last.todo.nil? rescue nil }
    #   end
    #   ReactiveRecord::ScopeDescription.hypertrace do
    #     break_on_enter?(:filter_records) { Todo.find(5).comments.last.todo.nil? rescue nil }
    #   end
    #   ReactiveRecord::Collection.hypertrace do
    #     break_on_enter?(:all) { Todo.find(5).comments.last.todo.nil? rescue nil }
    #     break_on_exit?(:all) { Todo.find(5).comments.last.todo.nil? rescue nil }
    #   end
    # end
    mgr.comments << FactoryGirl.create(:comment, comment: "Me BOSS", todo: user1.assigned_todos.last)
    page.should have_content('MANAGER SAYS: The Boss Speaks')
    page.should have_content('BOSS SAYS: The Boss Speaks')
    wait_for_ajax
    page.should_not have_content('MANAGER SAYS: Me BOSS', wait: 0)
    page.should_not have_content('BOSS SAYS: Me BOSS', wait: 0)
    #pause
    # evaluate_ruby do
    #   ReactiveRecord::Collection.hypertrace(instrument: :all)
    # end
    #pause
    #puts "here we go!!!!!!!!!!"
    user1.update_attribute(:manager, mgr)
    #puts evaluate_ruby "User.find(#{user1.id}).update_attribute(:manager, #{mgr.id})"
    page.should have_content('MANAGER SAYS: Me BOSS')
    page.should have_content('BOSS SAYS: Me BOSS')
    evaluate_ruby("ReactiveRecord::Base.last_fetch_at").should eq(starting_fetch_time)
    #pause
  end
end
