require 'spec_helper'
require 'test_components'

describe "column types on client", js: true do

  before(:all) do
    # TimeXternal - lets us easily get back time values
    # that will look like client json strings.
    class Timex

      def initialize(time = nil)
        if time.is_a? Time
          @time = time
        elsif time.is_a? Timex
          @time = time.time.dup
        elsif time
          @time = Time.new(time.localtime)
        else
          @time = Time.new
        end
      end

      def method_missing(m, *args, &b)
        val = time.send(m, *args, &b)
        val = Timex.new(val) if val.is_a? Time
        val
      end

      def as_json
        strftime("%Y-%m-%dT%H:%M:%S%z").gsub(/\+0000$/, '-0000')
      end

      attr_reader :time

      def time_only
        utc_time = Timex.new(self).utc
        start_time = Time.parse('2000-01-01T00:00:00.000-00:00').utc
        Timex.new(start_time+(utc_time-utc_time.beginning_of_day.to_i).to_i).localtime
      end

      class << self
        def at(x)
          Timex.new(Time.at(x))
        end
        def sqlmin
          Timex.new(Time.parse('2001-01-01T00:00:00.000-00:00').localtime)
        end
        def parse(s)
          Timex.new(Time.parse(s))
        end
      end
    end

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

    TypeTest.build_tables #rescue nil
    DefaultTest.build_tables #rescue nil

    isomorphic do
      class TypeTest < ActiveRecord::Base
        server_method :a_server_method, default: "hello" do |s=""|
          s.reverse
        end
      end
      class DefaultTest < ActiveRecord::Base
      end
    end

    ActiveRecord::Base.instance_variable_set(:@public_columns_hash, nil)

  end

  before(:each) do
    stub_const 'ApplicationPolicy', Class.new
    ApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end

    size_window(:small, :portrait)

    TypeTest.delete_all

    DefaultTest.delete_all
  end

  it 'transfers the columns hash to the client' do
    expect_evaluate_ruby do
      TypeTest.columns_hash
    end.to eq(TypeTest.columns_hash.as_json)
    check_errors
  end

  it 'defines the server method with a default value' do
    expect_evaluate_ruby do
      TypeTest.new.a_server_method()
    end.to eq('hello')
    check_errors
  end

  it 'loads the server method' do
    TypeTest.create
    expect_promise do
      ReactiveRecord.load { TypeTest.find(1).a_server_method('hello') }
    end.to eq('olleh')
    check_errors
  end

  it 'creates a dummy value of the appropriate type' do
    t = Time.now
    TypeTest.create(
      boolean: true,
      date: t,
      datetime: t,
      decimal: 12.2,
      float: 13.2,
      integer: 14,
      bigint: 15,
      string: "hello",
      text: "goodby",
      time: t,
      timestamp: t,
      json: {kind: :json},
      jsonb: {kind: :jsonb}
    )
    expect do
      TypeTest.columns_hash.collect do |attr, _info|
        TypeTest.find(1).send(attr).class
      end
    end.to_on_client eq([
      'Number', 'NilClass', 'Boolean', 'Date', 'Time', 'Number', 'Number', 'Number',
      'Number', 'String', 'String', 'Time', 'Time', 'NilClass', 'NilClass'
    ])
    check_errors
  end

  it 'will not override a default of nil if the attribute is serialized' do
    isomorphic do
      TypeTest.serialize :string
      TypeTest.serialize :text
    end
    %i[string text].each_with_index do |attr, i|
      # find a different record for each iteration to prevent finding a model
      # which is loaded
      expect { TypeTest.find(i + 1)[attr].class }.on_client_to eq('NilClass')
    end
  end

  it 'while loading the dummy value delegates the correct type with operators etc' do
    t = Time.parse('1/2/2003')
    TypeTest.create(
      boolean: true,
      date: t,
      datetime: t,
      decimal: 12.2,
      float: 13.2,
      integer: 14,
      bigint: 15,
      string: "hello",
      text: "goodby",
      time: t,
      timestamp: t # see default tests below for json and jsonb
    )
    expect do
      t = TypeTest.find(1)
      [
        !t.boolean, t.date+1, t.datetime+2.days, t.decimal + 5, t.float + 6, t.integer + 7,
        t.bigint + 8, t.string.length, t.text.length, t.time+3.days, t.timestamp+4.days
      ]
    end.on_client_to eq([
      true, "2001-01-02", (Timex.sqlmin+2.days).as_json, 5, 6, 7,
      8, 0, 0, (Timex.sqlmin+3.days).as_json, (Timex.sqlmin+4.days).as_json
    ])
    check_errors
  end

  it 'loads and converts the value' do  # randomly generates an error, but the exactual spec passed... perhaps move it up or down? (tried moving down one step)
    t = Timex.parse('1/2/2003')
    TypeTest.create(
      boolean: true,
      date: t.time,
      datetime: t.time,
      decimal: 12.2,
      float: 13.2,
      integer: 14,
      bigint: 15,
      string: "hello",
      text: "goodby",
      time: t.time,
      timestamp: t.time,
      json: {kind: :json},
      jsonb: {kind: :jsonb}
    )
    expect do
      Hyperstack::Model.load do
        TypeTest.columns_hash.collect do |attr, _info|
          [TypeTest.find(1).send(attr).class, TypeTest.find(1).send(attr)]
        end.flatten
      end
    end.to_then eq([
      'Number', 1,
      'NilClass', nil,
      'Boolean', true,
      'Date', t.to_date.as_json,
      'Time', t.as_json,
      'Number', 12.2,
      'Number', 13.2,
      'Number', 14,
      'Number', 15,
      'String', 'hello',
      'String', 'goodby',
      'Time', t.time_only.as_json, # date is indeterminate for active record time
      'Time', t.as_json,
      'Hash', {'kind' => 'json'},
      'Hash', {'kind' => 'jsonb'}
    ])
    check_errors
  end

  it 'converts a time string to a time on writing' do
    expect_evaluate_ruby do
      test = TypeTest.new
      test.datetime = "1/1/2001"
      (test.datetime + 1.minute)
    end.to eq((Timex.parse("1/1/2001") + 1.minute).as_json)
  end

  it 'converts a integer to a time on writing' do
    expect_evaluate_ruby do
      test = TypeTest.new
      test.datetime = 12
      test.datetime + 60.seconds
    end.to eq((Timex.at(12)+60.seconds).as_json)
    check_errors
  end

  it 'converts a float to a time on writing' do
    expect_evaluate_ruby do
      test = TypeTest.new
      test.datetime = 12.2
      test.datetime + 60.9
    end.to eq((Timex.at(12.2)+60.9).as_json)
    check_errors
  end

  it 'converts a 0, "false" false and nil to a boolean false, everything else is true' do
    expect_evaluate_ruby do
      [0, 'false', false, nil, 'hi', 17, [], true].collect do |val|
        TypeTest.new(boolean: val).boolean
      end
    end.to eq([false, false, false, false, true, true, true, true])
    check_errors
  end

  it 'booleans also have a ? accessor method' do
    expect_evaluate_ruby do
      [true, false].collect do |val|
        TypeTest.new(boolean: val).boolean?
      end
    end.to eq([true, false])
    check_errors
  end

  it 'converts other dates just like time' do
    expect_evaluate_ruby do
      [:datetime, :time, :timestamp].collect do |attr|
        TypeTest.new(attr => 12).send(attr)
      end.uniq
    end.to eq([Timex.at(12).as_json])
  end

  it 'converts floats, decimals, integers and bigints' do
    expect_evaluate_ruby do
      [:float, :decimal, :integer, :bigint].collect do |attr|
        TypeTest.new(attr => 12.5).send(attr) +
        TypeTest.new(attr => "12.2").send(attr) +
        TypeTest.new(attr => -12.2).send(attr)
      end.uniq
    end.to eq([12.5, 12])
    check_errors
  end

  it 'converts strings and text' do
    expect_evaluate_ruby do
      [:string, :text].collect do |attr|
        [TypeTest.new(attr => 12).send(attr), TypeTest.new(attr => '12').send(attr)]
      end.flatten.uniq
    end.to eq(['12'])
    check_errors
  end

  it 'uses the default value if specified for the dummy value' do
    r = DefaultTest.create(string: "no no no")
    expect_evaluate_ruby do
      t = DefaultTest.find(1)
      [
        t.string, t.date, t.datetime, t.integer_from_string, t.integer_from_int,
        t.float_from_string, t.float_from_float,
        t.boolean_from_falsy_string, t.boolean_from_truthy_string, t.boolean_from_falsy_value,
        t.json[:kind], t.jsonb[:kind]  # the default for json and jsonb is nil so we will test dummy operations here
      ]
    end.to eq([
      "I'm a string!", r.date.as_json, Timex.new(r.datetime.localtime).as_json, 99, 98,
      0.02, 0.01,
      false, true, false,
      'json', 'jsonb'
    ])
    check_errors
  end

  it 'uses the default value if even if the attribute is serialized' do
    isomorphic do
      DefaultTest.serialize :string
    end
    expect_evaluate_ruby do
      DefaultTest.find(1).string
    end.to eq("I'm a string!")
  end

  it 'uses the default value if specified when initializing a new record' do
    expect_evaluate_ruby do
      DefaultTest.new.string
    end.to eq("I'm a string!")
    check_errors
  end

  it 'uses the default value when initializing a new record & can be saved' do
    starting_fetch_id = evaluate_ruby("ReactiveRecord::Base.current_fetch_id")
    expect_promise do
      record = DefaultTest.new
      record.string = record.string.reverse
      record.save
    end.to be_truthy
    expect(DefaultTest.find(1).string).to eq("!gnirts a m'I")
    expect_evaluate_ruby("ReactiveRecord::Base.current_fetch_id").to eq(starting_fetch_id)
  end

  it 'handles a serialized attribute properly' do
    isomorphic do
      class TypeTest < ActiveRecord::Base
        serialize :text
      end
    end
    r = TypeTest.create(text: [{'foo' => {'bar' => 12}}, 13])
    expect_promise do
      ReactiveRecord.load { TypeTest.find(1).text }
    end.to eq(r.text)
  end

end
