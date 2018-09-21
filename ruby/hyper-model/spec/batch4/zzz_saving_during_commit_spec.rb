require 'spec_helper'
require 'test_components'
require 'rspec-steps'

describe "saving during commit", js: true do

  before(:each) do
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

    class ActiveRecord::Base
      class << self
        def public_columns_hash
          @public_columns_hash ||= {}
        end
      end
    end

    class CommitIssue < ActiveRecord::Base
      def self.build_tables
        connection.create_table :commit_issues, force: true do |t|
          t.string :name
          t.timestamps
        end
        ActiveRecord::Base.public_columns_hash[name] = columns_hash
      end
    end

    CommitIssue.build_tables #rescue nil

    isomorphic do
      class CommitIssue < ActiveRecord::Base
        after_create :save_again
        def save_again
          save
        end
      end
    end

    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    size_window(:small, :portrait)
  end

  it "broadcast even if saving during after_save" do
    CommitIssue.create(name: 1)
    mount "CommitIssueTest" do
      class CommitIssueTest < React::Component::Base
        render do
          "all: [#{CommitIssue.all.pluck(:name)}]"
        end
      end
    end
    page.should have_content('all: [1]')
    CommitIssue.create(name: 2)
    page.should have_content('all: [1,2]')
  end

end
