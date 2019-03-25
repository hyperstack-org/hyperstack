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
    Hyperstack.configuration do |config|
      config.transport = :crud_only
    end
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
      class SpeedTester < HyperComponent
        def self.load_all(id)
          Hyperstack::Component::IsomorphicHelpers.load_context
          start_time = Time.now
          timer_promise = Promise.new
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
            # puts gets clock to sync otherwise its slightly inaccurate
          end.then do
            after(0) { timer_promise.resolve(Time.now-start_time) }
          end
          timer_promise
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
    binding.pry
  end
end

=begin
results:
with improvements:
measure(1, 9, 9, 9)
********* Total Time 10.760204 ***********************
            process_vectors: 7.729447 (71)%
            building cache_items: 7.713941 (71)%
            save_records: 2.569092 (23)%
            as_json: 0.457144 (4)%
            active_record: 0.44621399999999695 (4)%
            apply_method lookup: 0.06301599999999652 (0)%
            root_lookup: 0.009902000000000168 (0)%
            public_columns_hash: 0.003181 (0)%
********* Other Time ***********************
measure(1, 7, 7, 7) (1372 data points fetched) vs 107 seconds w/o fixes
********* Total Time 3.230448 ***********************
            process_vectors: 1.854479 (57)%
            building cache_items: 1.847171 (57)%
            save_records: 1.197451 (37)%
            active_record: 0.19789300000000268 (6)%
            as_json: 0.175386 (5)%
            apply_method lookup: 0.030857000000000908 (0)%
            root_lookup: 0.004622000000000015 (0)%
            public_columns_hash: 0.001442 (0)%
********* Other Time ***********************
processed in 2.449s with getters fixed
processed in 2.420s with setters fixed
processed in 2.392s without React set or get state
processed in 1.551s with hashing used instead of detects
=end
