require 'spec_helper'
require 'test_components'

describe "ReactiveRecord::ServerDataCache.get_model" do

  before(:each) do
    ActiveRecord::Base.public_columns_hash
  end

  it "will raise an access violation for an unloaded class" do
    expect { ReactiveRecord::ServerDataCache.get_model('UnloadedClass') }.to raise_exception
  end

  it "will not raise an access violation for an AR model in the Models folder" do
    expect(ReactiveRecord::ServerDataCache.get_model('Comment')).to eq Comment
  end

  it "will not raise an access violation if the class is already loaded" do
    expect(UnloadedClass).to eq ReactiveRecord::ServerDataCache.get_model('UnloadedClass')
  end

end
