require 'spec_helper'

describe "unnamed and non-standard pluralized relationships and models", js: true do

  before(:all) do
    class ActiveRecord::Base
      class << self
        def public_columns_hash
          @public_columns_hash ||= {}
        end
      end
    end

    class Criterium < ActiveRecord::Base
      def self.build_tables
        connection.create_table :criteria, force: true do |t|
          t.string :name
          t.belongs_to :my_model
          t.belongs_to :other_model
          t.timestamps
        end
        ActiveRecord::Base.public_columns_hash[name] = columns_hash
      end
    end

    class MyModel < ActiveRecord::Base
      def self.build_tables
        connection.create_table :my_models, force: true do |t|
          t.string :name
          t.timestamps
        end
        ActiveRecord::Base.public_columns_hash[name] = columns_hash
      end
    end

    class OtherModel < ActiveRecord::Base
      def self.build_tables
        connection.create_table :other_models, force: true do |t|
          t.string :name
          t.timestamps
        end
        ActiveRecord::Base.public_columns_hash[name] = columns_hash
      end
    end

    Criterium.build_tables #rescue nil
    MyModel.build_tables #rescue nil
    OtherModel.build_tables #rescue nil
  end

  before(:each) do

    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new

    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
    end


    isomorphic do
      class Criterium < ActiveRecord::Base
        belongs_to :other_model
      end

      class MyModel < ActiveRecord::Base
        has_many :criteria
      end

      class OtherModel < ActiveRecord::Base
      end
    end

    @other_model = OtherModel.create(name: 'other_model1')
    criterium = Criterium.create(other_model: @other_model)
    my_model = MyModel.new(name: 'my_model1')
    my_model.criteria << criterium
    my_model.save

    size_window(:small, :portrait)
  end

  it "will follow relationships through non standard inflected models without inverse relationships" do
    expect_promise do
      Hyperstack::Model.load do
        MyModel.first.criteria.first.other_model.name
      end
    end.to eq(@other_model.name)
  end
end
