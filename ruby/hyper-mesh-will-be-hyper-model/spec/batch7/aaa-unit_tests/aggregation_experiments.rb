require 'spec_helper'
require 'rspec-steps'

describe "aggregation experiments" do
  it "even AR models (that are aggregates) are immutable" do
    user = User.new
    address = user.address
    address.save
    address.reload
    user.save
    user.reload
    expect(user.address).not_to eq(address)
    user.address = address
    user.save
    user.reload
    expect(user.address).to eq(address)
  end

  it "updating an aggregate does NOT change the container" do
    user = User.new
    expect { user.address.state = "philly" }.to raise_error
    address = user.address
    user.address.save
    expect(user).not_to be_changed
    user.address = address
    expect(user).to be_changed
  end

end
