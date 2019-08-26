require 'spec_helper'
require 'test_components'

describe 'callbacks', js: true do
  before(:all) do
    class ActiveRecord::Base
      class << self
        def public_columns_hash
          @public_columns_hash ||= {}
        end
      end
    end
  end

  describe 'before_validation :callback_method on create', js: true do
    before(:each) do
      policy_allows_all

      isomorphic do
        class ModelWithCallback < ActiveRecord::Base

          def self.build_tables
            connection.create_table(:model_with_callbacks, force: true) do |t|
              t.integer :call_count, default: 0
              t.timestamps
            end
            ActiveRecord::Base.public_columns_hash[name] = columns_hash
          end

          before_validation :callback_method, on: :create

          def callback_method
            self.call_count += 1
          end
        end
      end

      ModelWithCallback.build_tables
    end

    it "should be called" do
      expect_promise do
        model = ModelWithCallback.new
        model.save.then do
          model.call_count
        end
      end.to eq 1
    end

  end
end
