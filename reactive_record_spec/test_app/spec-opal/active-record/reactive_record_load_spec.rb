require 'spec_helper'

describe "ReactiveRecord.load" do

  it "will not find a non-existing record" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      User.find_by_first_name("Jon").id
    end.then do |id|
      expect(id).to be_nil
    end
  end

  it "will find an existing record" do
    React::IsomorphicHelpers.load_context
    ReactiveRecord.load do
      User.find_by_email("todd@catprint.com").id
    end.then do |id|
      expect(id).not_to be_nil
    end
  end

end
