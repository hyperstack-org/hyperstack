class DefaultTest < ActiveRecord::Base
def self.build_tables
    connection.create_table :default_tests, force: true do |t|
      t.string   :string,                     default: "I'm a string!"
      t.date     :date,                       default: Date.today
      t.datetime :datetime,                   default: Time.now
      t.integer  :integer_from_string,        default: "99"
      t.integer  :integer_from_int,           default: 98
      t.float    :float_from_string,          default: "0.02"
      t.float    :float_from_float,           default: 0.01
      t.boolean  :boolean_from_falsy_string,  default: "OFF"
      t.boolean  :boolean_from_truthy_string, default: "something-else"
      t.boolean  :boolean_from_falsy_value,   default: false
      t.json     :json,                       default: {kind: :json}
      t.jsonb    :jsonb,                      default: {kind: :jsonb}
    end
  end
end
