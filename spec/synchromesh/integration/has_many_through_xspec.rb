require 'spec_helper'
require 'synchromesh/integration/test_components'

describe "has_many through relationships", js: true do


  before(:all) do
    require 'pusher'
    require 'pusher-fake'
    Pusher.app_id = "MY_TEST_ID"
    Pusher.key =    "MY_TEST_KEY"
    Pusher.secret = "MY_TEST_SECRET"
    require "pusher-fake/support/base"

    HyperMesh.configuration do |config|
      config.transport = :pusher
      config.channel_prefix = "synchromesh"
      config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
    end

    class Physician < ActiveRecord::Base
      def self.build_tables
        connection.create_table :physicians, force: true do |t|
          t.string :name
          t.timestamps
        end
      end
    end

    class Patient < ActiveRecord::Base
      def self.build_tables
        connection.create_table :patients, force: true do |t|
          t.string :name
          t.timestamps
        end
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
      end
    end
  end

  before(:each) do

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

    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end

    size_window(:small, :portrait)
  end

  it "works with has_many :through relationships" do

    mount "PhysicianSchedule" do
      class PhysicianSchedule < React::Component::Base
        render(DIV) do
          Physician.all.each do |doc|
            DIV do
              DIV { "Dr. #{doc.name}'s schedule'" }
              UL do
                doc.appointments.each do |appt|
                  LI do
                    "#{appt.patient.name} at #{appt.appointment_date}"
                  end
                end
              end
              if doc.appointments.empty?
                DIV { "no appointments" }
              else
                DIV { "total of #{doc.appointments.count} appointments"}
                DIV { "patient list: " }
                UL do
                  doc.patients.each do |patient|
                    LI { patient.name }
                  end
                end
              end
            end
          end
        end
      end
    end
    ds = Physician.create(name: "Stop")
    #df = Physician.create(name: "Faith")
    #dq = Physician.create(name: "Quack")
    pc = Patient.create(name: "H. Chrondriac")
    #pl = Patient.create(name: "B. Legg")
    #ph = Patient.create(name: "N. Help")
    #pause
    evaluate_ruby do
      PhysicianSchedule.hypertrace instrument: :all
      #ReactiveRecord::Collection.hypertrace do
      #  instrument :all
        #break_on_enter?(:related_records_for) { |record| @association.attribute == 'patients' }
      #end
    end
    Appointment.create(appointment_date: Time.now+1.day, physician: ds, patient: pc)
    pause
    evaluate_ruby do
      Appointment.create(
        appointment_date: Time.now+1.day,
        physician: Physician.find_by_name('Stop'),
        patient: Patient.find_by_name('B. Legg')
      )
    end
    pause
  end
end
