require 'spec_helper'
require 'test_components'

describe "reactive-record edge cases", js: true do

  before(:all) do
    # Hyperstack.configuration do |config|
    #   config.transport = :simple_poller
    #   # slow down the polling so wait_for_ajax works
    #   config.opts = { seconds_between_poll: 2 }
    # end

    require 'pusher'
    require 'pusher-fake'
    Pusher.app_id = "MY_TEST_ID"
    Pusher.key =    "MY_TEST_KEY"
    Pusher.secret = "MY_TEST_SECRET"
    require "pusher-fake/support/base"

    Hyperstack.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = "synchromesh"
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret, use_tls: false}.merge(PusherFake.configuration.web_options)
    end

  end

  before(:each) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all unless policy.obj.is_a?(Todo) && policy.obj.title == 'secret' }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    size_window(:small, :portrait)
  end

  it "will load all the policies when the system starts" do
    expect(defined? SomeModelPolicy).to be_falsy
    User.create(name: 'Fred')
    expect(defined? SomeModelPolicy).to be_truthy
  end


  it "prerenders a belongs to relationship", :prerendering_on do
    # must be first otherwise check for ajax fails because of race condition
    # with previous test
    user_item = User.create(name: 'Fred')
    todo_item = TodoItem.create(title: 'test-todo', user: user_item)
    mount "PrerenderTest", {}, render_on: :server_only do
      class PrerenderTest < HyperComponent
        render(DIV) do
          TodoItem.first.user.name
        end
      end
    end
    page.should have_content("Fred")
  end

  it "trims the association tree" do
    5.times do |i|
      user = FactoryBot.create(:user, first_name: i) unless i == 3
      FactoryBot.create(:todo, title: "User #{i}'s todo", owner: user)
    end
    expect_promise do
      HyperMesh.load do
        Todo.all.collect do |todo|
          todo.owner && todo.owner.first_name
        end.compact
      end
    end.to contain_exactly('0', '1', '2', '4')
  end

  it "does not double count local saves" do
    expect_promise do
      HyperMesh.load do
        Todo.count
      end.then do |count|
        Todo.create(title: 'test todo')
      end.then do
        Todo.count
      end
    end.to eq(1)
  end

  it "fetches data during prerendering", :prerendering_on do
    5.times do |i|
      FactoryBot.create(:todo, title: "Todo #{i}")
    end
    # cause spec to fail if there are attempts to fetch data after prerendering
    hide_const 'ReactiveRecord::Operations::Fetch'
    mount "TestComponent77", {}, render_on: :both do
      class TestComponent77 < HyperComponent
        render(UL) do
          Todo.each do |todo|
            LI { todo.title }
          end
        end
      end
    end
    Todo.all.each do |todo|
      page.should have_content(todo.title)
    end
  end

  it "destroy receives any errors added by the server" do
    class Todo < ActiveRecord::Base
      before_destroy do
        return true unless title == "don't destroy me"
        errors.add :base, "Can't destroy me"
        throw(:abort)
      end
    end
    id = Todo.create(title: "don't destroy me").id
    expect do
      Hyperstack::Model.load do
        @todo = Todo.find(id)
      end.then do |todo|
        todo.destroy.then do |response|
          todo.errors.messages unless response[:success]
        end
      end
    end.on_client_to eq("base" => ["Can't destroy me"])
    expect { @todo.destroyed?}.on_client_to be_falsy
  end


  it "the limit and offset predefined scopes work" do
    5.times do |i|
      FactoryBot.create(:todo, title: "Todo #{i}")
    end
    mount "TestComponent77" do
      class TestComponent77 < HyperComponent
        render(UL) do
          Todo.limit(2).offset(3).each do |todo|
            LI { todo.title }
          end
        end
      end
    end
    Todo.limit(2).offset(3).each do |todo|
      page.should have_content(todo.title)
    end
  end

  it 'will return nil instead of raising an access violation for finder methods' do
    FactoryBot.create(:todo, title: 'secret')
    expect_promise do
      Hyperstack::Model.load do
        Todo.find_by_title('secret')
      end
    end.to be_nil
    expect_promise do
      Hyperstack::Model.load do
        Todo.find(2)
      end
    end.to be_nil
    expect_promise do
      Hyperstack::Model.load do
        Todo.find_by(title: 'secret')
      end
    end.to be_nil
  end

  it "will reload scopes when data arrives too late" do
    class ActiveRecord::Base
      class << self
        def public_columns_hash
          @public_columns_hash ||= {}
        end
      end
    end

    class BelongsToModel < ActiveRecord::Base
      def self.build_tables
        connection.create_table :belongs_to_models, force: true do |t|
          t.string :name
          t.belongs_to :has_many_model
          t.timestamps
        end
        ActiveRecord::Base.public_columns_hash[name] = columns_hash
      end
    end

    class HasManyModel < ActiveRecord::Base
      def self.build_tables
        connection.create_table :has_many_models, force: true do |t|
          t.string :name
          t.timestamps
        end
        ActiveRecord::Base.public_columns_hash[name] = columns_hash
      end
    end

    BelongsToModel.build_tables #rescue nil
    HasManyModel.build_tables #rescue nil

    isomorphic do
      class BelongsToModel < ActiveRecord::Base
        belongs_to :has_many_model
      end

      class HasManyModel < ActiveRecord::Base
        has_many :belongs_to_models
      end
    end

    class HasManyModel < ActiveRecord::Base
      def belongs_to_models
        sleep 0.3 if name == "sleepy-time"
        super
      end
    end

    class ActiveRecord::Base
      alias orig_synchromesh_after_create synchromesh_after_create
      def synchromesh_after_create
        sleep 0.4 if try(:name) == "sleepy-time"
        orig_synchromesh_after_create
      end
    end

    has_many1 = HasManyModel.create(name: "has_many1")
    2.times { |i| BelongsToModel.create(name: "belongs_to_#{i}", has_many_model: has_many1) }
    expect { HasManyModel.first.belongs_to_models.count }.on_client_to eq(1)
    BelongsToModel.create(name: "sleepy-time", has_many_model: has_many1)
    expect { Hyperstack::Model.load { HasManyModel.first.belongs_to_models.count } }.on_client_to eq(3)
  end

  describe 'can use finder methods on scopes' do

    before(:each) do
      isomorphic do
        Todo.finder_method :with_title do |title|
          find_by_title(title)
        end
        Todo.scope :completed, -> () { where(completed: true) }
      end
      FactoryBot.create(:todo, title: 'todo 1', completed: true)
      FactoryBot.create(:todo, title: 'todo 2', completed: true)
      FactoryBot.create(:todo, title: 'todo 1', completed: false)
      FactoryBot.create(:todo, title: 'todo 2', completed: false)
      FactoryBot.create(:todo, title: 'secret', completed: true)
    end

    it 'find_by_xxx' do
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find_by_title('todo 2').id
        end
      end.to eq(Todo.completed.find_by_title('todo 2').id)
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find_by_title('todo 3')
        end
      end.to be_nil
    end

    it 'find' do
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find(2).title
        end
      end.to eq(Todo.completed.find(2).title)
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find(3)
        end
      end.to be_nil
    end

    it 'find with id array' do
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find(1,2).map(&:id)
        end
      end.to eq(Todo.completed.find(1,2).map(&:id))
    end

    it 'find with id array returns nil values' do
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find(2,3,4,5,6).map {|todo| todo.is_a?(Todo) ? todo.id : todo}
        end
      end.to eq([2,nil,nil,nil,nil])
    end

    it 'find_by' do
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find_by(title: 'todo 2').id
        end
      end.to eq(Todo.completed.find_by(title: 'todo 2').id)
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find_by(title: 'todo 3')
        end
      end.to be_nil
    end

    it "and will return nil unless access is allowed" do
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find_by_title('secret')
        end
      end.to be_nil
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find(5)
        end
      end.to be_nil
      expect_promise do
        Hyperstack::Model.load do
          Todo.completed.find_by(title: 'secret')
        end
      end.to be_nil
    end
  end
end
