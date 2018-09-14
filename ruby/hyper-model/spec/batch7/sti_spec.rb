require 'spec_helper'
require 'test_components'
require 'rspec-steps'

RSpec::Steps.steps "class inheritance", js: true do

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

    class ApplicationPolicy
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
  end

  before(:each) do

    class ActiveRecord::Base
      class << self
        def public_columns_hash
          @public_columns_hash ||= {}
        end
      end
    end

    isomorphic do

      class BaseClass < ActiveRecord::Base
        self.abstract_class = true
        scope :a_scope, -> () {}, regulate: :always_allow
      end

      class SubClass < BaseClass
        def self.build_tables
          connection.create_table :sub_classes, force: true do |t|
            t.string :xxx
            t.timestamps
          end
          ActiveRecord::Base.public_columns_hash[name] = columns_hash
        end
      end

      class SubSubClass < SubClass
        def self.build_tables
          connection.create_table :sub_sub_classes, force: true do |t|
            t.string :xxx
            t.timestamps
          end
          ActiveRecord::Base.public_columns_hash[name] = columns_hash
        end
      end

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

        class SubClass2 < Base
        end

        class NoSyncSubClass1 < Base
          do_not_synchronize
        end

        class NoSyncSubClass2 < Base
          do_not_synchronize
        end
      end

      class Funky < ActiveRecord::Base
        self.primary_key = :funky_id
        #self.inheritance_column = :funky_type
        def self.build_tables
          connection.create_table :funkies, force: true do |t|
            t.string :funky_type
            t.timestamps
          end
          ActiveRecord::Base.public_columns_hash[name] = columns_hash
        end
      end


      class BelongsTo < ActiveRecord::Base
        belongs_to :has_many
        belongs_to :has_one
        belongs_to :best_friend, class_name: "HasMany", foreign_key: :bf_id
      end

      class HasMany < ActiveRecord::Base
        has_many :belongs_to
        has_many :best_friends, class_name: "BelongsTo", foreign_key: :bf_id
      end

      class HasOne < ActiveRecord::Base
        has_one :belongs_to
      end

      class Scoped < ActiveRecord::Base
        scope :only_those_guys, -> () {}
      end
    end

    [SubClass, SubSubClass, Sti::Base, Funky].each { |klass| klass.build_tables }

  end

  it "will use the subclass name to set the type" do
    binding.pry
    evaluate_ruby('Sti::SubClass1.create(data: "record 1")')
    expect_promise('Sti::Base.last.load(:type)').to eq('Sti::SubClass1')
  end

  it "will return the correct class when finding the record" do
    Sti::NoSyncSubClass1.create(data: 'record 2')
    expect(evaluate_ruby("Sti::Base.find_by_data('record 2').itself.class")).to eq('Sti::Base')
    expect_promise do
      ReactiveRecord.load { Sti::Base.find_by_data("record 2").itself.class }
    end.to eq('Sti::NoSyncSubClass1')
  end

  it "will change the type when the type field is updated" do
    evaluate_ruby 'Sti::Base.find_by_data("record 2").type = "Sti::NoSyncSubClass2"'
    expect_evaluate_ruby('Sti::Base.find_by_data("record 2").class').to eq('Sti::NoSyncSubClass2')
  end

  it "will scope STI classes based on the class type" do
    evaluate_ruby "React::IsomorphicHelpers.load_context"
    expect_promise("ReactiveRecord.load { Sti::SubClass1.count }").to eq(Sti::SubClass1.count)
    expect_promise("ReactiveRecord.load { Sti::Base.count }").to eq(Sti::Base.count)
    expect_promise("ReactiveRecord.load { Sti::NoSyncSubClass1.count }").to eq(Sti::NoSyncSubClass1.count)
    Sti::SubClass1.create
    Sti::Base.create
    evaluate_promise("Sti::NoSyncSubClass1.create")
    expect_evaluate_ruby("Sti::Base.count").to eq(Sti::Base.count)
    expect_evaluate_ruby("Sti::SubClass1.count").to eq(Sti::SubClass1.count)
    expect_evaluate_ruby("Sti::NoSyncSubClass1.count").to eq(Sti::NoSyncSubClass1.count)
  end

  it "will scope STI classes when the type changes" do
    expect_promise do
      ReactiveRecord.load do
        Sti::NoSyncSubClass1.first.itself
      end.then do |record|
        record.update(type: 'Sti::NoSyncSubClass2')
      end.then do
        Sti::NoSyncSubClass1.count
      end
    end.to eq(Sti::NoSyncSubClass1.count)
  end

  it "STI classes can inherit scopes" do
    expect_promise do
      ReactiveRecord.load { Sti::SubClass1.a_scope.count }
    end.to eq(Sti::SubClass1.a_scope.count)
  end

  it "Concrete classes can inherit scopes from Abstract classes" do
    SubClass.create(xxx: 'instance 1')
    expect_promise do
      ReactiveRecord.load { SubClass.a_scope.count }
    end.to eq(SubClass.a_scope.count)
  end
end
