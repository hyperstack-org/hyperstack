require 'spec_helper'

describe "dummy values" do

  before(:each) { React::IsomorphicHelpers.load_context }

  it "fetches a dummy value" do
    expect(User.find_by_email("mitch@catprint.com").first_name.to_s.is_a?(String)).to be_truthy
  end

  it "can convert the value to a float" do
    expect(User.find_by_email("mitch@catprint.com").id.to_f.is_a?(Float)).to be_truthy
  end

  it "can convert the value to an int" do
    expect(User.find_by_email("mitch@catprint.com").id.to_i.is_a?(Integer)).to be_truthy
  end

  it "can do math on a value" do
    expect(1 + User.find_by_email("mitch@catprint.com").id).to eq(1)
  end

  xit "can do string things as well" do # can't because of the way strings work in opal
    expect("id: " + User.find_by_email("mitch@catprint.com").id).to eq("id: ")
  end

end
