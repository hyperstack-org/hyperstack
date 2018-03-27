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
    size_window(:large, :landscape)
    FactoryBot.create(:user, first_name: 'Lily', last_name: 'DaDog')
    User.validates :last_name, exclusion: { in: %w[f**k], message: 'no swear words allowed' }
  end

  # it "can access attributes using the [] operator" do
  #   expect_promise do
  #     HyperMesh.load do
  #       User.find_by_first_name('Lily')
  #     end.then do |lily|
  #       lily[:last_name] = 'DerDog'
  #       lily.save
  #     end
  #   end.to be_truthy
  #   expect_evaluate_ruby("User.find_by_first_name('Lily')[:last_name]").to eq('DerDog')
  #   expect(User.find_by_first_name('Lily')[:last_name]).to eq('DerDog')
  # end

  it "can validate only" do
    expect_promise do
      User.new(last_name: 'f**k').validate.tap { |p| puts "got the promise in spec" }.then do |new_user|
        puts "promise resolved in spec"
        new_user.errors.messages
      end
    end.to eq("last_name" => ["no swear words allowed"])
  end
end
