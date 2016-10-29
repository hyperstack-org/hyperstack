require 'spec_helper'

use_case "reading and writting enums" do

  async "can change the enum and read it back" do
    React::IsomorphicHelpers.load_context
    set_acting_user "super-user"
    user = User.find(1)
    user.test_enum = :no
    user.save.then do
      React::IsomorphicHelpers.load_context
      ReactiveRecord.load do
        User.find(1).test_enum
      end.then do |test_enum|
        async { expect(test_enum).to eq(:no) }
      end
    end
  end

  async "can set it back" do
    React::IsomorphicHelpers.load_context
    set_acting_user "super-user"
    user = User.find(1)
    user.test_enum = :yes
    user.save.then do
      React::IsomorphicHelpers.load_context
      ReactiveRecord.load do
        User.find(1).test_enum
      end.then do |test_enum|
        async { expect(test_enum).to eq(:yes) }
      end
    end
  end

  it "can change it back" do
    user = User.find(1)
    user.test_enum = :yes
    user.save.then do |success|
      expect(success).to be_truthy
    end
  end

end
