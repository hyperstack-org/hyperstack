class TypeTest < ActiveRecord::Base
  def self.build_tables
    connection.create_table(:type_tests, force: true) do |t|
      t.binary(:binary)
      t.boolean(:boolean)
      t.date(:date)
      t.datetime(:datetime)
      t.decimal(:decimal, precision: 5, scale: 2)
      t.float(:float)
      t.integer(:integer)
      t.bigint(:bigint)
      t.string(:string)
      t.text(:text)
      t.time(:time)
      t.timestamp(:timestamp)
      t.json(:json)
      t.jsonb(:jsonb)
    end
  end
end
