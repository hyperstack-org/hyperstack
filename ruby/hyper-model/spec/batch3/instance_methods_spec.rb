require 'spec_helper'
require 'test_components'

describe "Misc Instance Methods", :no_reset, js: true do

  before(:each) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all) { true }
    end
  end

  it "increment!" do
    user = FactoryBot.create(:user, first_name: 'zero', data_times: 0)
    user_id = user.id
    evaluate_ruby { User.find(user_id).increment!(:data_times) }
    expect(user.reload.data_times).to eq(1)
    expect { User.find(user_id).data_times }.to_on_client eq(1)
  end

  it "decrement!" do
    user = FactoryBot.create(:user, first_name: 'one', data_times: 1)
    user_id = user.id
    evaluate_ruby { User.find(user_id).decrement!(:data_times) }
    expect(user.reload.data_times).to eq(0)
    expect { User.find(user_id).data_times }.to_on_client eq(0)
  end
end
