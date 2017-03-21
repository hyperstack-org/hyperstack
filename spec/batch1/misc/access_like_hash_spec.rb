require 'spec_helper'
require 'test_components'
require 'rspec-steps'


RSpec::Steps.steps "access like a hash", js: true do

  before(:step) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    size_window(:small, :portrait)
    FactoryGirl.create(:user, first_name: 'Lily', last_name: 'DaDog')
  end

  it "can access attributes using the [] operator" do
    expect_promise do
      HyperMesh.load do
        User.find_by_first_name('Lily')
      end.then do |lily|
        lily[:first_name]
      end
    end.to eq('Lily')
  end

  it "can update attributes using the []= operator" do
    expect_promise do
      HyperMesh.load do
        User.find_by_first_name('Lily')
      end.then do |lily|
        lily[:last_name] = 'DerDog'
        lily.save
      end
    end.to be_truthy
    expect(User.find_by_first_name('Lily')[:last_name]).to eq('DerDog')
  end
end
