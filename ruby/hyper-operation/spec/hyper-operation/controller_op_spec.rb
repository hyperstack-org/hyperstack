require 'spec_helper'

describe "controller operations", js: true do
  before(:each) do
    Hyperloop::HyperloopController.class_eval do
      def a_controller_method
        12
      end
    end
    stub_const "MyControllerOp", Class.new(Hyperloop::ControllerOp)
    isomorphic do
      class MyControllerOp < Hyperloop::ControllerOp
        param :data
        step { a_controller_method if params.data }
      end
    end
  end
  it "can run uplink to a controller method and will delegate to the controller" do
    expect_promise do
      MyControllerOp.run(data: 'hello')
    end.to eq(12)
  end
  it "connects globally and broadcasts to the session channel" do
    Hyperloop.configuration do |config|
      config.connect_session = true
    end
    mount 'SessionApp' do
      class SessionApp < Hyperloop::Component
        after_mount { MyControllerOp.on_dispatch { |params| mutate.message params.data } }
        render { state.message }
      end
    end
    MyControllerOp.dispatch_to { session_channel }
    evaluate_ruby do
      MyControllerOp.run(data: 'hello')
    end
    expect(page).to have_content('hello')
  end
  it "connects locally and broadcasts to the session channel" do
    Hyperloop.configuration do |config|
      config.connect_session = false
    end
    mount 'SessionApp' do
      class SessionApp < Hyperloop::Component
        after_mount { Hyperloop.connect_session }
        after_mount { MyControllerOp.on_dispatch { |params| mutate.message params.data } }
        render { state.message }
      end
    end
    MyControllerOp.dispatch_to { session_channel }
    evaluate_ruby do
      MyControllerOp.run(data: 'hello')
    end
    expect(page).to have_content('hello')
  end
end
#
#     it "will pass server failures back" do
#       ServerFacts.param :acting_user, nils: true
#       expect_promise do
#         ServerFacts.run(n: -1).fail { |exception| Promise.new.resolve(exception) }
#       end.to eq('N is too small')
#       expect_promise do
#         ServerFacts.run(n: 10000000000).fail { |exception| Promise.new.resolve(exception) }
#       end.to eq('stack level too deep')
#     end
#
#     it "pass validation failures back" do
#       ServerFacts.param :acting_user, nils: true
#       class ServerFacts < Hyperloop::ServerOp
#         validate { false }
#       end
#       expect_promise do
#         ServerFacts.run(n: 5).fail { |exception| Promise.new.resolve(exception) }
#       end.to include('param validation 1 failed')
#     end
#
#     it "will reject uplinks that don't accept acting_user" do
#       expect_promise do
#         ServerFacts.run(n: 5).fail { |exception| Promise.new.resolve(exception) }
#       end.to include('Hyperloop::AccessViolation')
#     end
#   end
#
#   context 'Downlinking' do
#
#     before(:all) do
#       require 'pusher'
#       require 'pusher-fake'
#       Pusher.app_id = "MY_TEST_ID"
#       Pusher.key =    "MY_TEST_KEY"
#       Pusher.secret = "MY_TEST_SECRET"
#       require "pusher-fake/support/base"
#
#       Hyperloop.configuration do |config|
#         config.transport = :pusher
#         config.channel_prefix = "synchromesh"
#         config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
#       end
#     end
#
#     before(:each) do
#       stub_const "Operation", Class.new(Hyperloop::ServerOp)
#       on_client do
#         class Test < React::Component::Base
#           before_mount do
#             Operation.on_dispatch do |params|
#               # password is for testing inbound param filtering
#               state.message! "#{params.message}#{params.try(:password)}"
#             end
#           end
#           render do
#             if state.message
#               "The server says '#{state.message}'!"
#             else
#               "No messages yet"
#             end
#           end
#         end
#       end
#     end
#
#     it 'will dispatch to the client' do
#       isomorphic do
#         class Operation < Hyperloop::ServerOp
#           param :message
#           param :password
#         end
#       end
#       stub_const "OperationPolicy", Class.new
#       OperationPolicy.always_allow_connection
#       mount 'Test'
#       expect(page).to have_content('No messages yet')
#       Operation.run(message: 'hello', password: 'better not see this')
#       expect(page).to have_content("The server says 'hello'!")
#     end
#
#     it 'will evaluate channels dynamically' do
#       isomorphic do
#         class Operation < Hyperloop::ServerOp
#           param :message
#           param :channels
#           dispatch_to { params.channels }
#         end
#       end
#       stub_const "ApplicationPolicy", Class.new
#       ApplicationPolicy.always_allow_connection
#       mount 'Test'
#       expect(page).to have_content('No messages yet')
#       Operation.run(message: 'hello', channels: 'Application')
#       expect(page).to have_content("The server says 'hello'!")
#     end
#
#     it 'will attach the channel with the regulate_connection' do
#       isomorphic do
#         class Operation < Hyperloop::ServerOp
#           param :message
#         end
#       end
#       stub_const "OperationPolicy", Class.new
#       OperationPolicy.regulate_class_connection { true }
#       mount 'Test'
#       expect(page).to have_content('No messages yet')
#       Operation.run(message: 'hello')
#       expect(page).to have_content("The server says 'hello'!")
#     end
#
#     it 'can regulate dispatches with the regulate_dispatches_from' do
#       isomorphic do
#         class Operation < Hyperloop::ServerOp
#           param :message
#           param :broadcast, default: false
#         end
#       end
#       stub_const "ApplicationPolicy", Class.new
#       ApplicationPolicy.always_allow_connection
#       ApplicationPolicy.regulate_dispatches_from(Operation) { params.broadcast }
#       mount 'Test'
#       expect(page).to have_content('No messages yet')
#       Operation.run(message: 'hello')
#       wait_for_ajax
#       expect(page).not_to have_content("The server says 'hello'!", wait: 0)
#       Operation.run(message: 'goodby', broadcast: true)
#       expect(page).to have_content("The server says 'goodby'!")
#     end
#
#     it 'can regulate dispatches with the regulate_dispatch applied to a policy' do
#       isomorphic do
#         class Operation < Hyperloop::ServerOp
#           param :message
#           param :broadcast, default: false
#         end
#       end
#       stub_const "ApplicationPolicy", Class.new
#       stub_const "OperationPolicy", Class.new
#       ApplicationPolicy.always_allow_connection
#       OperationPolicy.dispatch_to { ['Application'] if params.broadcast }
#       mount 'Test'
#       expect(page).to have_content('No messages yet')
#       Operation.run(message: 'hello')
#       wait_for_ajax
#       expect(page).not_to have_content("The server says 'hello'!", wait: 0)
#       Operation.run(message: 'goodby', broadcast: true)
#       expect(page).to have_content("The server says 'goodby'!")
#     end
#
#     it 'will regulate with the always_dispatch_from regulation' do
#       isomorphic do
#         class Operation < Hyperloop::ServerOp
#           param :message
#         end
#       end
#       stub_const "ApplicationPolicy", Class.new
#       ApplicationPolicy.always_allow_connection
#       ApplicationPolicy.always_dispatch_from(Operation)
#       mount 'Test'
#       expect(page).to have_content('No messages yet')
#       Operation.run(message: 'hello')
#       expect(page).to have_content("The server says 'hello'!")
#     end
#   end
# end
