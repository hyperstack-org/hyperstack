# frozen_string_literal: true

require "spec_helper"

describe "ActiveRecord::ClassMethods", js: true do
  context "method_missing" do
    it "should return a TypeError if name is nil" do
      expect_evaluate_ruby do
        error = nil

        begin
          User.send(nil)
        rescue StandardError => e
          error = e
        end

        error
      end.to eq("nil is not a symbol nor a string")
    end
  end
end
