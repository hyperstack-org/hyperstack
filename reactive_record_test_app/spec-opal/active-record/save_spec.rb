require 'spec_helper'

describe "simple record update and save" do

  it "can find an existing model" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      User.find_by_email("mitch@catprint.com").first_name
    end.then do |first_name|
      expect(first_name).to be("Mitch")
    end
  end

  it "doesn't find the model changed" do
    expect(User.find_by_email("mitch@catprint.com")).not_to be_changed
  end

  it "the model is not new" do
    expect(User.find_by_email("mitch@catprint.com")).not_to be_new
  end

  it "the model is not saving" do
    expect(User.find_by_email("mitch@catprint.com")).not_to be_saving
  end

  it "an attribute can be changed" do
    mitch = User.find_by_email("mitch@catprint.com")
    mitch.first_name = "Mitchell"
    expect(mitch.first_name).to eq("Mitchell")
  end  # TODO this was broken

  it "and the attribute will be marked as changed"do
    expect(User.find_by_email("mitch@catprint.com")).to be_changed
  end

  it "saving? is true while the model is being saved" do
    mitch = User.find_by_email("mitch@catprint.com")
    mitch.save.then {}.tap { expect(mitch).to be_saving }
  end

  it "after saving changed? will be false" do
    expect(User.find_by_email("mitch@catprint.com")).not_to be_changed
  end  # TODO this was broken

  it "after saving saving? will be false" do
    expect(User.find_by_email("mitch@catprint.com")).not_to be_saving
  end

  it "the data has been persisted to the database" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      User.find_by_email("mitch@catprint.com").first_name
    end.then do |first_name|
      expect(first_name).to eq("Mitchell")
    end
  end  # TODO this was broken

  it "after saving within the block saving? will be false" do
    mitchell = User.find_by_email("mitch@catprint.com")
    mitchell.first_name = "Mitch"
    mitchell.save.then do
      expect(mitchell).not_to be_saving
    end
  end

  async "the save block receives the correct block parameters" do
    mitch = User.find_by_email("mitch@catprint.com")
    mitch.first_name = "Mitchell"
    mitch.save do | success, message, models |
      async do
        expect(success).to be_truthy
        expect(message).to be_nil
        expect(models).to eq([mitch])
        expect(mitch.errors).to be_empty
      end
    end
  end

  it "the save promise receives the response hash" do
    mitch = User.find_by_email("mitch@catprint.com")
    mitch.first_name = "Mitch"
    mitch.save.then do | response |
      expect(response[:success]).to be_truthy
      expect(response[:message]).to be_nil
      expect(response[:models]).to eq([mitch])
    end
  end

  async "the save will fail if validation fails" do
    mitch = User.find_by_email("mitch@catprint.com")
    mitch.email = "mitch at catprint dot com"
    mitch.save do |success, message, models|
      async do
        expect(success).to be_falsy
        expect(message).to be_present
        expect(models).to eq([mitch])
      end
    end
  end

  it "validation errors are put in the errors object" do
    mitch = User.find_by_email("mitch@catprint.com")
    mitch.email = "mitch at catprint dot com"
    mitch.save.then do |success, message, models|
      expect(mitch.errors[:email]).to eq(["is invalid"])
    end
  end

  it "within the save block saving? is false if validation fails" do
    mitch = User.find_by_email("mitch@catprint.com")
    mitch.email = "mitch at catprint dot com"
    mitch.save.then do
      expect(mitch).not_to be_saving
    end
  end

  it "if validation fails changed? is still true" do
    mitch = User.find_by_email("mitch@catprint.com")
    mitch.email = "mitch at catprint dot com"
    mitch.save.then do
      expect(mitch).to be_changed
    end
  end
end
