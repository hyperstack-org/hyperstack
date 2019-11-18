require 'spec_helper'
require 'test_components'
require 'rspec-steps'


RSpec::Steps.steps "validate and valid? methods", js: true do

  before(:step) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    User.do_not_synchronize
    TestModel.do_not_synchronize
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    %i[last_name first_name].each do |attr|
      User.validates attr, exclusion: { in: %w[f**k], message: 'no swear words allowed' }
    end
    TestModel.validates_presence_of :child_models
    client_option raise_on_js_errors: :off # TURN OFF BROADCAST SO TESTS DON"T EFFECT EACH OTHER
  end

  after(:step) do
    # Turn broadcasting back on
    TestModel.instance_variable_set :@do_not_synchronize, false
    User.instance_variable_set :@do_not_synchronize, false
  end

  it "can validate the presence of an association on a new record" do
    expect_promise do
      @test_model = TestModel.new
      @test_model.validate.then { |test_model| test_model.errors.messages }
    end.not_to be_empty
    expect_promise do
      @test_model.child_models << ChildModel.new
      @test_model.validate.then { |test_model| test_model.errors.messages }
    end.to be_empty
    expect(TestModel.count).to be_zero
    expect(ChildModel.count).to be_zero
  end

  it "can validate the presence of an association on a saved record" do
    expect(TestModel.count).to be_zero
    expect(ChildModel.count).to be_zero

    expect_promise do
      @child = ChildModel.new
      @test_model = TestModel.new(child_models: [@child])
      @test_model.save.then { |r| @test_model.errors.messages }
    end.to be_empty

    expect_promise do
      @child.destroy.then do |d|
        @test_model = TestModel.find_by_id(@test_model.id)
        @test_model.validate(force: true).then do |test_model| # why force is needed ?
          test_model.errors.messages
        end
      end
    end.to_not be_empty
  end

  it "can validate only using the validate method" do
    expect_promise do
      User.new(last_name: 'f**k').validate.then do |new_user|
        new_user.errors.messages
      end
    end.to eq("last_name"=>["no swear words allowed"])
  end

  it "can validate and use the full_messages method" do
    expect_promise do
      User.new(last_name: 'f**k').validate.then do |new_user|
        new_user.errors.full_messages
      end
    end.to eq(["Last name no swear words allowed"])
  end

  it "the valid? method will return true if the model has no errors" do
    mount "Validator" do
      class Validator < HyperComponent
        include Hyperstack::Component::IsomorphicHelpers
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
      user.save(validate: true).then { |result| user.valid?}
    end.to be_falsy
  end

  it "save without validate should save invalid record" do
    expect_promise do
      user = User.new(last_name: 'f**k')
      user.save(validate: false).then { |result| user.new_record?}
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

  it "previous errors are cleared on each validation" do
    expect_promise do
      user = User.new(last_name: 'f**k')
      user.validate.then do
        user.last_name = 'doggie'
        user.first_name = 'f**k'
        user.validate.then do |new_user|
          new_user.errors.full_messages
        end
      end
    end.to eq(["First name no swear words allowed"])
  end

end
