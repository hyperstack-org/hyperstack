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
      #always_allow_connection  TURN OFF BROADCAST SO TESTS DON"T EFFECT EACH OTHER
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    size_window(:large, :landscape)
    User.validates :last_name, exclusion: { in: %w[f**k], message: 'no swear words allowed' }
    client_option raise_on_js_errors: :off
  end

  it "can validate only using the validate method" do
    expect_promise do
      User.new(last_name: 'f**k').validate.tap { |p| puts "got the promise in spec" }.then do |new_user|
        new_user.errors.messages
      end
    end.to eq("last_name"=>[{"message"=>"no swear words allowed"}])
  end

  it "the valid? method will return true if the model has no errors" do
    mount "Validator" do
      class Validator < Hyperloop::Component
        include React::IsomorphicHelpers
        class << self
          attr_reader :model
        end
        before_first_mount { @model = User.new }
        render(DIV) { "#{Validator.model}.valid? #{!!Validator.model.valid?}" }
      end
    end
    expect_promise do
      user = User.new(last_name: 'dog')
      user.save.then { user.valid? }
    end.to be_truthy
  end

  it "the valid? method will return false if the model has errors" do
    expect_promise do
      user = User.new(last_name: 'f**k')
      user.save.then { user.valid? }
    end.to be_falsy
  end

  it "the valid? method reacts to the model being saved" do
    evaluate_ruby do
      Validator.model.last_name = 'f**k'
    end
    expect(page).to have_content('.valid? true')
    evaluate_ruby do
      Validator.model.save
    end
    expect(page).to have_content('.valid? false')
    evaluate_ruby do
      Validator.model.update(last_name: 'nice doggy')
    end
    expect(page).to have_content('.valid? true')
  end

  it "the valid? method reacts to the model being validated" do
    evaluate_ruby do
      Validator.model.last_name = 'f**k'
    end
    evaluate_ruby do
      Validator.model.validate
    end
    expect(page).to have_content('.valid? false')
    evaluate_ruby do
      Validator.model.last_name = 'nice doggy'
      Validator.model.validate
    end
    expect(page).to have_content('.valid? true')
  end

  it "the valid? method reacts to the error object changing state" do
    expect(page).to have_content('.valid? true')
    evaluate_ruby do
      Validator.model.errors.add(:bite)
    end
    expect(page).to have_content('.valid? false')
    evaluate_ruby do
      Validator.model.errors.clear
    end
    expect(page).to have_content('.valid? true')
  end
end
