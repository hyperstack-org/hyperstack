require 'spec_helper'

describe "isomorphic operations", js: true do

  let(:response_spy) { spy('response_spy') }

  before(:each) do

    allow(Hyperstack::ServerOp).to receive(:run_from_client).and_wrap_original do |m, *args|
      m.call(*args).tap { |r| response_spy.status = r[:status] }
    end

    on_client do
      class Test
        include Hyperstack::Component
        include Hyperstack::State::Observable
        class << self
          observer :receive_count do
            @@rc ||= 0
            @@rc
          end
          mutator :rc_inc do
            @@rc ||= 0
            @@rc += 1
          end
        end
        before_mount do
          receives(Operation) do |params|
            self.class.rc_inc
            # password is for testing inbound param filtering
            mutate @message = "#{params.message}#{params.try(:password)}"
          end
        end
        render do
          if @message
            "The server says '#{@message}'!"
          else
            "No messages yet"
          end
        end
      end
    end
  end

  context 'uplinking' do
    before(:each) do
      stub_const "ServerFacts", Class.new(Hyperstack::ServerOp)
      isomorphic do
        class ServerFacts < Hyperstack::ServerOp
          param :n, type: Integer, min: 0

          class << self
            attr_accessor :executed
            def fact(x)
              (x.zero?) ? 1 : x * fact(x-1)
            end
          end

          step { ServerFacts.executed = true }
          step { ServerFacts.fact(params.n) }
        end
      end
    end
    it "can run a method on the server" do
      ServerFacts.param :acting_user, nils: true
      expect_promise do
        ServerFacts.run(n: 5)
      end.to eq(ServerFacts.fact(5))
      expect(ServerFacts.executed).to be true
      expect_evaluate_ruby('ServerFacts.executed').to be nil
    end

    it "will pass server failures back" do
      ServerFacts.param :acting_user, nils: true

      expect_promise do
        ServerFacts.run(n: -1).fail { |exception| Promise.new.resolve(exception.inspect) }
      end.to eq('#<Hyperstack::Operation::ValidationException: n is too small>')
      expect(response_spy).to have_received(:status=).with(400)
      expect_promise do
        ServerFacts.run(n: 10000000000).fail { |exception| Promise.new.resolve(exception.inspect) }
      end.to eq('#<Exception: stack level too deep>')
      expect(response_spy).to have_received(:status=).with(500)
    end

    it "pass abort status back" do
      # just to check we will actually interrogate the structure of the exception in this spec
      ServerFacts.param :acting_user, nils: true
      class ServerFacts < Hyperstack::ServerOp
        step { abort! }
      end
      expect do
        ServerFacts.run(n: 5).fail do |exception|
          Promise.new.resolve(exception.inspect)
        end
      end.on_client_to eq("#<Hyperstack::Operation::Exit: failed>")
      expect(response_spy).to have_received(:status=).with(500)
    end

    it "pass failure data back" do
      # just to check we will actually interrogate the structure of the exception in this spec
      ServerFacts.param :acting_user, nils: true
      class ServerFacts < Hyperstack::ServerOp
        step { raise 'failure' }
        failed { [{'some' => 'data'}] }
      end
      expect_promise do
        ServerFacts.run(n: 5).fail do |exception|
          Promise.new.resolve(exception)
        end
      end.to eq([{'some' => 'data'}])
      expect(response_spy).to have_received(:status=).with(500)
    end

    it "pass validation failures back" do
      # just to check we will actually interrogate the structure of the exception in this spec
      ServerFacts.param :acting_user, nils: true
      class ServerFacts < Hyperstack::ServerOp
        validate { false }
      end
      expect_promise do
        ServerFacts.run(n: 5).fail do |exception|
          Promise.new.resolve(exception.errors.message_list)
        end
      end.to eq(['param validation 1 failed'])
      expect(response_spy).to have_received(:status=).with(400)
    end

    it "will reject uplinks that don't accept acting_user" do
      expect_promise do
        ServerFacts.run(n: 5).fail { |exception| Promise.new.resolve(exception) }
      end.to include('Hyperstack::AccessViolation')
      expect(response_spy).to have_received(:status=).with(403)
    end
  end

  context 'Downlinking' do

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

    before(:each) do
      stub_const "Operation", Class.new(Hyperstack::ServerOp)
    end

    it 'will dispatch to the client' do
      isomorphic do
        class Operation < Hyperstack::ServerOp
          param :message
          inbound :password
        end
      end
      stub_const "OperationPolicy", Class.new
      OperationPolicy.always_allow_connection
      mount 'Test'
      expect(page).to have_content('No messages yet')
      Operation.run(message: 'hello', password: 'better not see this')
      expect(page).to have_content("The server says 'hello'!")
    end

    it 'will unmount a receiver' do
      isomorphic do
        class Operation < Hyperstack::ServerOp
          param :message
          inbound :password
        end
      end
      stub_const "OperationPolicy", Class.new
      OperationPolicy.always_allow_connection
      mount 'OuterTest' do
        class OuterTest
          include Hyperstack::Component
          include Hyperstack::State::Observable
          render do
            if Test.receive_count.zero?
              Test()
            else
              "test not mounted"
            end
          end
        end
      end
      expect(page).to have_content("No messages yet")
      Operation.run(message: 'hello', password: 'better not see this')
      expect(page).to have_content('test not mounted')
      Operation.run(message: 'hello again', password: 'better not see this')
      wait_for_ajax
      expect_evaluate_ruby('Test.receive_count').to eq(1)
    end

    it 'will evaluate channels dynamically' do
      isomorphic do
        class Operation < Hyperstack::ServerOp
          param :message
          param :channels
          dispatch_to { params.channels }
        end
      end
      stub_const "ApplicationPolicy", Class.new
      ApplicationPolicy.always_allow_connection
      mount 'Test'
      expect(page).to have_content('No messages yet')
      Operation.run(message: 'hello', channels: 'Application')
      expect(page).to have_content("The server says 'hello'!")
    end

    it 'will attach the channel with the regulate_connection' do
      isomorphic do
        class Operation < Hyperstack::ServerOp
          param :message
        end
      end
      stub_const "OperationPolicy", Class.new
      OperationPolicy.regulate_class_connection { true }
      mount 'Test'
      expect(page).to have_content('No messages yet')
      Operation.run(message: 'hello')
      expect(page).to have_content("The server says 'hello'!")
    end

    it 'can regulate dispatches with the regulate_dispatches_from' do
      isomorphic do
        class Operation < Hyperstack::ServerOp
          param :message
          param :broadcast, default: false
        end
      end
      stub_const "ApplicationPolicy", Class.new
      ApplicationPolicy.always_allow_connection
      ApplicationPolicy.regulate_dispatches_from(Operation) { params.broadcast }
      mount 'Test'
      expect(page).to have_content('No messages yet')
      Operation.run(message: 'hello')
      wait_for_ajax
      expect(page).not_to have_content("The server says 'hello'!", wait: 0)
      Operation.run(message: 'goodby', broadcast: true)
      expect(page).to have_content("The server says 'goodby'!")
    end

    it 'will regulate with the always_dispatch_from regulation' do
      isomorphic do
        class Operation < Hyperstack::ServerOp
          param :message
        end
      end
      stub_const "ApplicationPolicy", Class.new
      ApplicationPolicy.always_allow_connection
      ApplicationPolicy.always_dispatch_from(Operation)
      mount 'Test'
      expect(page).to have_content('No messages yet')
      Operation.run(message: 'hello')
      expect(page).to have_content("The server says 'hello'!")
    end

    it 'will dispatch to channel only once on run, even if dispatched multiple times during run' do
      isomorphic do
        class Operation < Hyperstack::ServerOp
          param :message
          param :channels
          dispatch_to { params.channels }
          dispatch_to { params.channels }
        end
      end
      stub_const "ApplicationPolicy", Class.new
      ApplicationPolicy.always_allow_connection
      mount 'Test'
      expect(page).to have_content('No messages yet')
      Operation.run(message: 'hello', channels: 'Application')
      expect(page).to have_content("The server says 'hello'!")
      expect_evaluate_ruby('Test.receive_count').to eq(1)
      Operation.run(message: 'hello', channels: 'Application')
      expect_evaluate_ruby('Test.receive_count').to eq(2)
    end
  end

  context "serialization overrides" do

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

    it 'calls the subclasses serializer and deserializer methods' do
      isomorphic do
        class Operation < Hyperstack::ServerOp
          param :acting_user, nils: true
          param :counter
          outbound :message
          step {params.message = 'hello'}
          step {params.counter + 1}
          def self.serialize_params(hash)
            # hash['counter'] += 1  # bug in unparser https://github.com/mbj/unparser/issues/117
            hash['counter'] = hash['counter'] + 1
            hash
          end
          def self.deserialize_params(hash)
            # hash['counter'] += 1  # bug in unparser https://github.com/mbj/unparser/issues/117
            hash['counter'] = hash['counter'] + 1
            hash
          end
          def self.serialize_response(response)
            response + 1
          end
          def self.deserialize_response(response)
            response + 1
          end
          def self.serialize_dispatch(hash)
            # hash[:message] += ' serialized' # bug in unparser https://github.com/mbj/unparser/issues/117
            hash[:message] = hash[:message] + ' serialized'
            hash
          end
          def self.deserialize_dispatch(hash)
            # hash[:message] += ' deserialized' # bug in unparser https://github.com/mbj/unparser/issues/117
            hash[:message] = hash[:message] + ' deserialized'
            hash
          end
        end
      end
      stub_const "OperationPolicy", Class.new
      OperationPolicy.always_allow_connection
      mount 'Test'

      expect_promise do
        Operation.run(counter: 1)
      end.to eq(6)
      expect(page).to have_content("The server says 'hello serialized deserialized'!")
    end

    it 'can attach custom headers' do
      isomorphic do
        class ControllerOperation < Hyperstack::ControllerOp

          def self.headers # this runs on the client and adds custom headers
            { Authorization: '1234' }
          end

          # return the value of the Authorization header
          # rails automatically upcases all the keys

          step { request.headers['AUTHORIZATION'] }
        end
      end
      # stub_const "ControllerOperationPolicy", Class.new
      # ControllerOperationPolicy.always_allow_connection
      mount 'Test'

      expect_promise do
        ControllerOperation.run
      end.to eq('1234')
    end

  end
end
