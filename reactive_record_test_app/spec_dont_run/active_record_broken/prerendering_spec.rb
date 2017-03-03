require 'spec_helper'
require 'components/test'

describe "prerendering" do

  it "will not return an id before preloading" do
    React::IsomorphicHelpers.load_context
    expect(User.find_by_email("mitch@catprint.com").id).not_to eq(1)
  end

# THIS IS FAILING BECAUSE WE ARE TRYING TO GRAB BROwSER DURING PRERENDERING
  async "preloaded the records" do
    `window.ClientSidePrerenderDataInterface.ReactiveRecordInitialData = undefined` rescue nil
    container = Element[Document.body].append('<div></div>').children.last
    complete = lambda do
      React::IsomorphicHelpers.load_context
      async do
        mitch = User.find_by_email("mitch@catprint.com")
        expect(mitch.id).to eq(1)
        expect(mitch.first_name).to eq("Mitch")
        expect(mitch.todo_items.first.title).to eq("a todo for mitch")
        expect(mitch.address.zip).to eq("14617")
        expect(mitch.todo_items.find_string("mitch").first.title).to eq("a todo for mitch")
        expect(mitch.todo_items.first.commenters.first.email).to eq("adamg@catprint.com")
        expect(mitch.expensive_math(13)).to eq(169)
        expect(mitch.detailed_name).to eq("M. VanDuyn - mitch@catprint.com (2 todos)")
        # clear out everything before moving on otherwise the initial data screws up the next test
        `delete window.ReactiveRecordInitialData`
        React::IsomorphicHelpers.load_context
      end
    end
    `container.load(#{"/test?ts=#{Time.now.to_i}"}, complete)`
  end

  async "does not preload everything" do
    `window.ClientSidePrerenderDataInterface.ReactiveRecordInitialData = undefined` rescue nil
    container = Element[Document.body].append('<div></div>').children.last
    complete = lambda do
      React::IsomorphicHelpers.load_context
      async do
        expect(User.find_by_email("mitch@catprint.com").last_name.to_s).to eq("")
        # clear out everything before moving on otherwise there will be a pending load that screw up the next test
        `delete window.ReactiveRecordInitialData`
        React::IsomorphicHelpers.load_context
      end
    end
    `container.load(#{"/test?ts=#{Time.now.to_i}"}, complete)`
  end

end
