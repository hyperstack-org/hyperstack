require 'spec_helper'
require 'test_components'
require 'rspec-steps'

RSpec::Steps.steps "record equality", js: true do

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

    class ApplicationPolicy
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
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

    isomorphic do
      module Sti
        class Base < ActiveRecord::Base
          def self.build_tables
            connection.create_table :bases, force: true do |t|
              t.string :type
              t.string :data
              t.timestamps
            end
            ActiveRecord::Base.public_columns_hash[name] = columns_hash
          end
          scope :a_scope, -> () {}, regulate: :always_allow
          scope :is_subclass1, -> () { where(type: 'Sti::SubClass1') }, regulate: :always_allow, client: -> { type == 'Base::SubClass1' }
        end

        class SubClass1 < Base
        end
      end
    end

    Sti::Base.build_tables

  end

  it "two records are the same if the point the same base record" do
    Sti::Base.create(data: 'record 1')
    expect_promise do
      Hyperstack::Model.load do
        Sti::Base.find(1) == Sti::Base.find_by_data('record 1')
      end
    end.to be_truthy
  end

  it "two records are not the same if they point to different records" do
    Sti::Base.create(data: 'record 2')
    expect_promise do
      Hyperstack::Model.load do
        Sti::Base.find(1) == Sti::Base.find_by_data('record 2')
      end
    end.to be_falsy
  end

  it "two new records are never the same" do
    expect_evaluate_ruby do
      Sti::Base.new(data: 'new record') == Sti::Base.new(data: 'new record')
    end.to be_falsy
  end

  it "a record is never something else" do
    expect_evaluate_ruby do
      Sti::Base.new(data: 'new record') == Object.new
    end.to be_falsy
  end

  it "an STI base record is the same record if the id's match" do
    expect_evaluate_ruby do
      Sti::Base.find(3) == Sti::SubClass1.find(3)
    end.to be_truthy
  end
end
