require 'spec_helper'
describe "self referencing belongs_to", js: true do

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

  before(:all) do
    class ActiveRecord::Base
      class << self
        def public_columns_hash
          @public_columns_hash ||= {}
        end
      end
    end

    class SelfRefModel < ActiveRecord::Base
      def self.build_tables
        connection.create_table :self_ref_models, force: true do |t|
          t.string :name
          t.string :other
          t.belongs_to :parent
          t.timestamps
        end
        ActiveRecord::Base.public_columns_hash[name] = columns_hash
      end
    end

    SelfRefModel.build_tables
  end

  before(:each) do

    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new

    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
    end

    isomorphic do
      class SelfRefModel < ActiveRecord::Base
        # the failure is caused by the has_many relationship coming first...
        has_many :children, class_name: 'SelfRefModel', foreign_key: 'parent_id'
        belongs_to :parent, class_name: 'SelfRefModel', required: false
      end
    end

    SelfRefModel.create(name: 'first model')
    SelfRefModel.create(name: 'second model')

    mount 'SelfRefModelIndex' do
      class SelfRefModelIndex < HyperComponent
        render(UL) do
          SelfRefModel.first.tap do |m|
            if m.parent && m.parent.id
              LI { "name: #{m.name}, parent id: #{m.parent.id}." }
            elsif !m.children.empty?
              LI { "name: #{m.name}, children: [#{m.children.collect(&:id)}]" }
            else
              LI { "name: #{m.name}." }
            end
          end
        end
      end
    end

    size_window(:small, :portrait)
  end

  it 'will be updated properly' do
    SelfRefModel.last.update(parent: SelfRefModel.first)
    expect(page).to have_content('name: first model, children: [2]')
    SelfRefModel.last.update(parent: nil)
    expect(page).to have_content('name: first model.')
    SelfRefModel.first.update(parent: SelfRefModel.last)
    expect(page).to have_content('name: first model, parent id: 2.')
  end
end
