require 'spec_helper'
require 'test_components'

describe "has_and_belongs_to_many", js: true do

  alias_method :on_client, :evaluate_ruby

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

    class ActiveRecord::Base
      class << self
        def public_columns_hash
          @public_columns_hash ||= {}
        end
      end
    end

    class Physician < ActiveRecord::Base
      def self.build_tables
        connection.create_table :physicians, force: true do |t|
          t.string :name
          t.timestamps
        end
        ActiveRecord::Base.public_columns_hash[name] = columns_hash
      end
    end

    class Patient < ActiveRecord::Base
      def self.build_tables
        connection.create_table :patients, force: true do |t|
          t.string :name
          t.timestamps
        end
        ActiveRecord::Base.public_columns_hash[name] = columns_hash
      end
    end

    class PatientsPhysicianStub < ActiveRecord::Base
      def self.build_tables
        connection.create_table :patients_physicians, force: true do |t|
          t.belongs_to :physician, index: true
          t.belongs_to :patient, index: true
        end
      end
    end

    Physician.build_tables #rescue nil
    PatientsPhysicianStub.build_tables #rescue nil
    Patient.build_tables #rescue nil

    isomorphic do
      class Physician < ActiveRecord::Base
        has_and_belongs_to_many :patients
      end

      class Patient < ActiveRecord::Base
        has_and_belongs_to_many :physicians
      end
    end
  end

  before(:each) do
    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end

    size_window(:medium)
  end

  it 'works' do
    mccoy = Physician.create(name: 'Dr. McCoy')
    Patient.create(name: 'James T. Kirk').physicians << mccoy
    expect { Physician.first.patients.count }.on_client_to eq(1)

    Patient.create(name: 'Spock').physicians << mccoy
    expect { Physician.first.patients.count }.on_client_to eq(2)

    on_client { Patient.create(name: 'Uhuru') }
    2.times do
      on_client { Patient.find(3).physicians << Physician.first }
      expect { Patient.find(3).physicians.count }.on_client_to eq(1)
      wait_for { Patient.find(3).physicians.count }.to eq(1)
      expect { Physician.first.patients.count }.on_client_to eq(3)
      expect(Physician.first.patients.count).to eq(3)

      on_client { Patient.find(3).physicians.destroy(Physician.first) }
      expect { Patient.find(3).physicians.count }.on_client_to eq(0)
      wait_for { Patient.find(3).physicians.count }.to eq(0)
      expect { Physician.first.patients.count }.on_client_to eq(2)
      expect(Physician.first.patients.count).to eq(2)
    end

    on_client { Patient.find(3).physicians.delete(Physician.first) }
    expect { Patient.find(3).physicians.count }.on_client_to eq(0)
    expect(Patient.find(3).physicians.count).to eq(0)
  end
end
