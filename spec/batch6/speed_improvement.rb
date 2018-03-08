require 'spec_helper'
require 'test_components'
#require 'reactive_record_factory'
#require 'rspec-steps'

#RSpec::Steps.steps 'Load From Json', js: true do
describe "speed tests", js: true do

  def build_records(users, todos_per_user, comments_per_user)
    User.destroy_all
    Comment.destroy_all
    TodoItem.destroy_all
    users.times do |u|
      user = User.create(name: "User#{u}")
      todos_per_user.times do |t|
        todo = TodoItem.create(title: "Todo #{u} - #{t}", user: user)
        comments_per_user.times do |c|
          Comment.create(comment: "Comment #{c}  #{u} - #{t}", user: user, todo_item: todo)
        end
      end
    end
  end

  def measure(test, users, todos_per_user, comments_per_user)
    build_records(users, todos_per_user, comments_per_user)
    evaluate_promise("SpeedTester.load_all(#{test})")
  end

  before(:all) do
    Hyperloop.configuration do |config|
      config.transport = :crud_only
    end
    #seed_database
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
  end

  before(:each) do
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    on_client do

      class SpeedTester < Hyperloop::Component
        def self.load_all(id)
          React::IsomorphicHelpers.load_context
          start_time = Time.now
          case id
          when 1
            ReactiveRecord.load do
              Comment.all.collect { |todo| todo.id }
            end.then do |ids|
              ReactiveRecord.load do
                ids.each do |id|
                  Comment.find(id).todo_item.user.name
                end
              end
            end
          when 2
            ReactiveRecord.load do
              User.each do |user|
                user.name
                user.todo_items.each do |todo|
                  todo.title
                  todo.comments.each do |comment|
                    comment.comment
                  end
                end
              end
            end
          when 3
            ReactiveRecord.load do
              Comment.all.collect { |todo| todo.id }
            end.then do |ids|
              ReactiveRecord.load do
                ids.each do |id|
                  Comment.find(id).comment
                end
              end
            end
          end.then{ Time.now-start_time }
        end

        after_mount do
          @start_time = Time.now
        end
        render(DIV) do
          DIV { "fetched in #{Time.now-@start_time} seconds"} if @start_time
          User.each do |user|
            LI do
              DIV do
                user.name.span
                UL do
                  user.todo_items.each do |todo|
                    LI do
                      DIV do
                        todo.title.span
                        UL do
                          todo.comments.each do |comment|
                            LI { comment.comment }
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    size_window(:large, :landscape)
  end


  it "can display 9 items" do
    build_records(3, 3, 3)
    #mount "SpeedTester"
    binding.pry
  end
end
