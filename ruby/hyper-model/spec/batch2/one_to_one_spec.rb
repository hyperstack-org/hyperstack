require 'spec_helper'
require 'test_components'
require 'rspec-steps'

describe "one to one relationships", js: true do

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
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret, use_tls: false}.merge(PusherFake.configuration.web_options)
    end

    class ActiveRecord::Base
      class << self
        def public_columns_hash
          @public_columns_hash ||= {}
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
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end

    size_window(:small, :large)

    isomorphic do

      class Parent < ActiveRecord::Base
        def self.build_tables
          connection.create_table :parents, force: true do |t|
            t.string :name
            t.timestamps
          end
          ActiveRecord::Base.public_columns_hash[name] = columns_hash
        end

        has_one :child
      end

      class Child < ActiveRecord::Base
        def self.build_tables
          connection.create_table :children, force: true do |t|
            t.string :name
            t.integer :parent_id
            t.timestamps
          end
          ActiveRecord::Base.public_columns_hash[name] = columns_hash
        end
        belongs_to :parent
      end
    end

    [Parent, Child].each { |klass| klass.build_tables }

  end

  def compare_to_server(model, expression, expected_result, load=true)
    server_side = eval("#{model.class}.find(#{model.id}).#{expression}")
    expect(server_side).to eq(expected_result)
    be_expected_result = expected_result.is_a?(Array) ? contain_exactly(*expected_result) : eq(expected_result)
    if load
      expect_promise("Hyperstack::Model.load { #{model.class}.find(#{model.id}).#{expression} }")
      .to be_expected_result
    else
      wait_for_ajax
      expect_evaluate_ruby("#{model.class}.find(#{model.id}).#{expression}").to be_expected_result
    end
  end

  before(:each) do
    Parent.delete_all
    Child.delete_all
    @parent1 = Parent.create(name: 'parent1')
    @child1 = Child.create(name: 'child1', parent: @parent1)
  end

  it 'will load the parent' do
    compare_to_server @child1, 'parent.name', 'parent1'
  end

  it 'will load the child' do
    compare_to_server @parent1, 'child.name', 'child1'
  end

  it 'saving parent and child from client' do
    expect_promise do
      Parent.new(name: 'parent', child: Child.new(name: 'child')).save.then do |response|
        response[:saved_models].collect { |m| m[1] }
      end
    end.to contain_exactly('Parent', 'Child')
  end
end
