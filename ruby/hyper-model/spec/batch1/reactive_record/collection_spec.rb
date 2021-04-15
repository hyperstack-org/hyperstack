# frozen_string_literal: true

require "spec_helper"

describe "ReactiveRecord::Collection", js: true do
  context "#create" do
    before(:each) { policy_allows_all }

    it "should not create any records if the parent is not saved" do
      expect_promise do
        error = nil

        user = User.new(first_name: "foo")

        begin
          user.comments.create(comment: "foobar")
        rescue StandardError => e
          error = e
        end

        error
      end.to eq("You cannot call create unless the parent is saved")

      expect(Comment.count).to eq(0)
    end

    it "should create a new record in a has many association" do
      user = FactoryBot.create(:user, first_name: "foo")

      expect_promise do
        user = User.find_by_first_name("foo")

        user.comments.create(comment: "foobar")
      end

      expect(user.comments.count).to eq(1)
    end

    it "should create multiple new records in a has many association" do
      user = FactoryBot.create(:user, first_name: "foo")

      expect_promise do
        user = User.find_by_first_name("foo")

        user.comments.create([{ comment: "foobar" }, { comment: "barfoo" }])
      end

      expect(user.comments.count).to eq(2)
    end

    it "should create a new record and a join record in a has many through association" do
      user = FactoryBot.create(:user, first_name: "foo")

      expect_promise do
        user = User.find_by_first_name("foo")

        user.commented_on_items.create(title: "foo", description: "bar")
      end

      expect(user.commented_on_items.count).to eq(1)
      expect(user.comments.count).to eq(1)
    end

    it "should create a multiple new records and join records in a has many through association" do
      user = FactoryBot.create(:user, first_name: "foo")

      expect_promise do
        user = User.find_by_first_name("foo")

        user.commented_on_items.create(
          [{ title: "foo", description: "bar" }, { title: "foo", description: "bar" }]
        )
      end

      expect(user.commented_on_items.count).to eq(2)
      expect(user.comments.count).to eq(2)
    end
  end
end
