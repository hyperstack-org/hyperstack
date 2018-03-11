require 'spec_helper'
#Opal::RSpec::Runner.autorun

class BaseClass < ActiveRecord::Base
end

class SubClass < BaseClass
end

class Funky < ActiveRecord::Base
  self.primary_key = :funky_id
  self.inheritance_column = :funky_type
end

class BelongsTo < ActiveRecord::Base
  belongs_to :has_many
  belongs_to :has_one
  belongs_to :best_friend, class_name: "HasMany", foreign_key: :bf_id
end

class HasMany < ActiveRecord::Base
  has_many :belongs_to
  has_many :best_friends, class_name: "BelongsTo", foreign_key: :bf_id
end

class HasOne < ActiveRecord::Base
  has_one :belongs_to
end

class Scoped < ActiveRecord::Base
  scope :only_those_guys, -> () {}
end

describe "ActiveRecord" do

  before(:all) { React::IsomorphicHelpers.load_context }

  after(:each) { React::API.clear_component_class_cache }

  # uncomment if you are having trouble with tests failing.  One non-async test must pass for things to work

  # describe "a passing dummy test" do
  #   it "passes" do
  #     expect(true).to be(true)
  #   end
  # end

  describe "reactive_record active_record base methods" do

    it "will find the base class" do
      expect(SubClass.base_class).to eq(BaseClass)
    end

    it "knows the primary key" do
      expect(BaseClass.primary_key).to eq(:id)
    end

    it "can override the primary key" do
      expect(Funky.primary_key).to eq(:funky_id)
    end

    it "knows the inheritance column" do
      expect(BaseClass.inheritance_column).to eq(:type)
    end

    it "can override the inheritance column" do
      expect(Funky.inheritance_column).to eq(:funky_type)
    end

    it "knows the model name" do
      expect(BaseClass.model_name).to eq("BaseClass")
    end

    it "can find a record by id" do
      expect(BaseClass.find(12).id).to eq(12)
    end

    it "has a find_by_xxx method" do
      expect(BaseClass.find_by_xxx("beer").xxx).to eq("beer")
    end

    it "will correctly infer the model type from the inheritance column" do
      expect(BaseClass.find_by_type("SubClass").class).to eq(SubClass)
      expect(BaseClass.find_by_type(nil).class).to eq(BaseClass)
    end

    it "can have a has_many association" do
      expect(HasMany.reflect_on_association(:belongs_to).klass.reflect_on_association(:has_many).klass).to eq(HasMany)
    end

    it "can have a has_one association" do
      expect(HasOne.reflect_on_association(:belongs_to).klass.reflect_on_association(:has_one).klass).to eq(HasOne)
    end

    it "can override the class and foreign_key values when creating an association" do
      reflection = HasMany.reflect_on_association(:best_friends)
      expect(reflection.klass).to eq(BelongsTo)
      expect(reflection.association_foreign_key).to eq(:bf_id)
    end

    it "can have a scoping method" do
      expect(Scoped.only_those_guys.respond_to? :all).to be_truthy
    end

    it "can type check parameters" do
      expect(SubClass._react_param_conversion({attr1: 1, attr2: 2, type: "SubClass", id: 123}.to_n, :validate_only)).to be(true)
    end

    it "can type check parameters with native wrappers" do
      expect(SubClass._react_param_conversion(Native({attr1: 1, attr2: 2, type: "SubClass", id: 123}.to_n), :validate_only)).to be(true)
    end

    it "will fail type checking if type does not match" do
      expect(SubClass._react_param_conversion({attr1: 1, attr2: 2, type: nil, id: 123}.to_n, :validate_only)).to be_falsy
    end

    it "will convert a hash to an instance" do
      ar = SubClass._react_param_conversion({attr1: 1, attr2: 2, type: "SubClass", id: 123}.to_n)
      expect(ar.attr1).to eq(1)
      expect(ar.attr2).to eq(2)
      expect(ar.id).to eq(123)
    end

  end

end
