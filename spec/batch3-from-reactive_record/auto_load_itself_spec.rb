require 'spec_helper'
require 'test_components'

describe "HyperMesh.load", js: true do

  before(:each) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
    end
    size_window(:small, :portrait)
  end

  it "uses itself to force loading" do
    user = FactoryGirl.create(:user, first_name: 'Ima')
    expect_promise do
      HyperMesh.load { User.find_by_first_name('Ima') }.then { |user| user.id }
    end.to eq(user.id)
  end
end
