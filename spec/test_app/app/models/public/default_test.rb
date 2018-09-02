class DefaultTest < ActiveRecord::Base
def self.build_tables
    connection.create_table :default_tests, force: true do |t|
    t.string :string, default: "I'm a string!"
    t.date :date, default: Date.today
    t.datetime :datetime, default: Time.now
    end
  end
end
