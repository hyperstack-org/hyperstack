require 'spec_helper'
require 'test_components'
require 'rspec-steps'

RSpec::Steps.steps "has_many through relationships", js: true do

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

    class Appointment < ActiveRecord::Base
      def self.build_tables
        connection.create_table :appointments, force: true do |t|
          t.belongs_to :physician, index: true
          t.belongs_to :patient, index: true
          t.datetime :appointment_date
          t.timestamps
        end
        ActiveRecord::Base.public_columns_hash[name] = columns_hash
      end
    end

    isomorphic do
      class Physician < ActiveRecord::Base
        has_many :appointments
        has_many :patients, through: :appointments
      end

      class Appointment < ActiveRecord::Base
        belongs_to :physician
        belongs_to :patient
      end

      class Patient < ActiveRecord::Base
        has_many :appointments
        has_many :physicians, through: :appointments
      end
    end

    Physician.build_tables rescue nil
    Appointment.build_tables rescue nil
    Patient.build_tables rescue nil

  end

  before(:step) do

    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end

    size_window(:small, :portrait)
  end

  it "will load has_many :through relationships" do
    mount "PhysicianSchedule" do
      class PhysicianSchedule < React::Component::Base
        render(DIV) do
          Physician.all.each do |doc|
            DIV do
              if doc.appointments.any?
                "Dr. #{doc.name} has a total of #{doc.appointments.count} appointments with: #{doc.patients.pluck(:name).join(", ")}"
              else
                "Dr. #{doc.name} has no appointments."
              end
            end
          end
          Patient.all.each do |patient|
            DIV do
              if patient.physicians.any?
                "#{patient.name} - Doctors: #{patient.physicians.pluck(:name).join(', ')}"
              else
                "#{patient.name} is not seeing any doctors"
              end
            end
          end
        end
      end
    end
    @ds = Physician.create(name: "Stop")
    @df = Physician.create(name: "Faith")
    @dq = Physician.create(name: "Quack")
    @pc = Patient.create(name: "H. Chrondriac")
    @pl = Patient.create(name: "B. Legg")
    @ph = Patient.create(name: "N. Help")
    @a1 = Appointment.create(appointment_date: Time.now+1.day, physician: @ds, patient: @pc)
    page.should have_content("Dr. Stop has a total of 1 appointments with: H. Chrondriac")
    page.should have_content("Dr. Faith has no appointments.")
    page.should have_content("Dr. Quack has no appointments.")
    page.should have_content("H. Chrondriac - Doctors: Stop")
    page.should have_content("B. Legg is not seeing any doctors")
    page.should have_content("N. Help is not seeing any doctors")
  end

  it "can add to existing relationships on the client" do
    evaluate_ruby do
      Appointment.create(
        appointment_date: Time.now+1.day,
        physician: Physician.find_by_name('Stop'),
        patient: Patient.find_by_name('B. Legg')
      )
    end
    page.should have_content("Dr. Stop has a total of 2 appointments with: H. Chrondriac, B. Legg")
    page.should have_content("Dr. Faith has no appointments.")
    page.should have_content("Dr. Quack has no appointments.")
    page.should have_content("H. Chrondriac - Doctors: Stop")
    page.should have_content("B. Legg - Doctors: Stop")
    page.should have_content("N. Help is not seeing any doctors")
  end

  it "can add to existing relationships from the server" do
    @a2 = Appointment.create(appointment_date: Time.now+1.day, physician: @df, patient: @pc)
    page.should have_content("Dr. Stop has a total of 2 appointments with: H. Chrondriac, B. Legg")
    page.should have_content("Dr. Faith has a total of 1 appointments with: H. Chrondriac")
    page.should have_content("Dr. Quack has no appointments.")
    page.should have_content("H. Chrondriac - Doctors: Stop, Faith")
    page.should have_content("B. Legg - Doctors: Stop")
    page.should have_content("N. Help is not seeing any doctors")
  end

  it "can update an existing relationship from the server" do
    @a2.update(physician: @dq)
    page.should have_content("Dr. Stop has a total of 2 appointments with: H. Chrondriac, B. Legg")
    page.should have_content("Dr. Faith has no appointments.")
    page.should have_content("Dr. Quack has a total of 1 appointments with: H. Chrondriac")
    page.should have_content("H. Chrondriac - Doctors: Stop, Quack")
    page.should have_content("B. Legg - Doctors: Stop")
    page.should have_content("N. Help is not seeing any doctors")
  end

  it "can destroy an existing relationship from the server" do
    @a1.destroy
    page.should have_content("Dr. Stop has a total of 1 appointments with: B. Legg")
    page.should have_content("Dr. Faith has no appointments.")
    page.should have_content("Dr. Quack has a total of 1 appointments with: H. Chrondriac")
    page.should have_content("H. Chrondriac - Doctors: Quack")
    page.should have_content("B. Legg - Doctors: Stop")
    page.should have_content("N. Help is not seeing any doctors")
  end
end
