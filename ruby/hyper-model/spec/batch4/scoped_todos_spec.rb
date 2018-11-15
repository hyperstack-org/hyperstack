require 'spec_helper'
require 'test_components'

describe "example scopes", js: true do

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
              -> { joins(todoz: { owner: :manager }).where('managers_users.id = author_id').distinct},
              joins: ['todoz.owner.manager', 'author'],
              client: -> { todoz.owner.manager == author }
      end
    end
    size_window(:small, :portrait)
  end

  it "runs the server side scopes okay" do
    expect(Todo.with_managers_comments).to be_empty
    expect(Comment.by_manager).to be_empty
    boss = FactoryBot.create(:user, first_name: :boss)
    employee = FactoryBot.create(:user, first_name: :fred, manager: boss)
    todo = FactoryBot.create(:todo, owner: employee)
    comment = FactoryBot.create(:comment, author: boss, todoz: todo)
    FactoryBot.create(:comment, author: employee, todoz: todo)
    FactoryBot.create(:comment, author: employee, todoz: FactoryBot.create(:todo, owner: employee))
    expect(Todo.with_managers_comments).to match_array [todo]
    expect(Comment.by_manager).to match_array [comment]
  end

  it "a complex client side scope" do

    mount "TestComponent3" do
      class UserTodos < HyperComponent
        render(DIV) do
          DIV { "todos by user with comments" }
          User.each do |user|
            DIV do
              DIV { "#{user.first_name}'s Todos'" }
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
      class ManagerComments < HyperComponent
        render(DIV) do
          if Todo.with_managers_comments.any?
            DIV { "managers comments" }
            UL do
              Todo.with_managers_comments.each do |todo|
                DIV do
                  "#{todo.owner.first_name} - #{todo.title}".span
                  UL do
                    todo.comments.each do |comment|
                      LI { "BOSS SAYS: #{comment.comment}" } if comment.author == todo.owner.manager
                    end; end; end; end; end
          else
            DIV { "no manager comments" }
          end; end; end
      class TestComponent3 < HyperComponent
        render do
          puts "RENDERING TESTCOMPONENT3"
          DIV do
            UserTodos {}
            ManagerComments {}
          end; end; end; end
    # evaluate_ruby do
    #   ReactiveRecord::Collection.hypertrace instrument: :all
    #   UserTodos.hypertrace instrument: :all
    # end
    starting_fetch_time = evaluate_ruby("ReactiveRecord::Base.current_fetch_id")
    #pause "about to add the boss"
    boss = FactoryBot.create(:user, first_name: :boss)
    #pause "about to add the employee"
    employee = FactoryBot.create(:user, first_name: :joe, manager: boss)
    #pause "about to add the todo"
    todo = FactoryBot.create(:todo, title: "joe's todo", owner: employee)
    wait_for_ajax
    evaluate_ruby("ReactiveRecord::Base.current_fetch_id").should eq(starting_fetch_time)
    #pause "adding a comment from the boss"
    comment = FactoryBot.create(:comment, comment: "The Boss Speaks", author: boss, todoz: todo)
    page.should have_content('The Boss Speaks')
    #pause "added the boss speaks"
    fred = FactoryBot.create(:user, role: :employee, first_name: :fred)
    #pause "fred added"
    fred.assigned_todos << FactoryBot.create(:todo, title: 'fred todo')
    #pause "added another todo to fred" # HAPPENS AFTER HERE.....
    evaluate_ruby do
      #   ReactiveRecord::Collection.hypertrace instrument: :all
      #   UserTodos.hypertrace instrument: :all

      mitch = User.new(first_name: :mitch)
      mitch.assigned_todos << Todo.new(title: 'mitch todo')
      mitch.save
    end
    wait_for_ajax
    #pause "mitch added"
    user1 = FactoryBot.create(:user, role: :employee, first_name: :frank)
    user2 = FactoryBot.create(:user, role: :employee, first_name: :bob)
    mgr   = FactoryBot.create(:user, role: :manager, first_name: :sally)
    #pause "frank, bob, and sally added"
    user1.assigned_todos << FactoryBot.create(:todo, title: 'frank todo 1')
    user1.assigned_todos << FactoryBot.create(:todo, title: 'frank todo 2')
    user2.assigned_todos << FactoryBot.create(:todo, title: 'bob todo 1')
    user2.assigned_todos << FactoryBot.create(:todo, title: 'bob todo 2')
    user1.commentz << FactoryBot.create(:comment, comment: "frank made this comment", todoz: user2.assigned_todos.first)
    user2.commentz << FactoryBot.create(:comment, comment: "bob made this comment", todoz: user1.assigned_todos.first)
    # evaluate_ruby do
    #   Hyperstack::IncomingBroadcast.hypertrace do
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

    mgr.commentz << FactoryBot.create(:comment, comment: "Me BOSS", todoz: user1.assigned_todos.last)
    page.should have_content('MANAGER SAYS: The Boss Speaks')
    page.should have_content('BOSS SAYS: The Boss Speaks')
    wait_for_ajax
    page.should_not have_content('MANAGER SAYS: Me BOSS', wait: 0)
    page.should_not have_content('BOSS SAYS: Me BOSS', wait: 0)
    user1.update_attribute(:manager, mgr)
    page.should have_content('MANAGER SAYS: Me BOSS')
    page.should have_content('BOSS SAYS: Me BOSS')
    evaluate_ruby("ReactiveRecord::Base.current_fetch_id").should eq(starting_fetch_time)
  end
end
