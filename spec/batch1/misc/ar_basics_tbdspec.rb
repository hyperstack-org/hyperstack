require 'spec_helper'
require 'test_components'
require 'rspec-steps'

RSpec::Steps.steps "AR Client Basics", js: true do

  before(:all) do
    on_client do

      class BaseClass < ActiveRecord::Base
        self.abstract_class = true
      end

      class SubClass < BaseClass
      end

      class SubSubClass < SubClass
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
    end
  end

  it "will find the base class" do
    expect_evaluate_ruby("SubSubClass.base_class").to eq("SubClass")
  end

  it "knows the primary key" do
    expect_evaluate_ruby("BaseClass.primary_key").to eq("id")
  end

  it "can override the primary key" do
    expect_evaluate_ruby("Funky.primary_key").to eq("funky_id")
  end

  it "knows the inheritance column" do
    expect_evaluate_ruby('BaseClass.inheritance_column').to eq('type')
  end

  it "can override the inheritance column" do
    expect_evaluate_ruby('Funky.inheritance_column').to eq('funky_type')
  end

  it "knows the model name" do
    expect_evaluate_ruby('BaseClass.model_name').to eq("BaseClass")
  end

  it "can find a record by id" do
    expect_evaluate_ruby('BaseClass.find(12).id').to eq(12)
  end

  it "has a find_by_xxx method" do
    expect_evaluate_ruby('BaseClass.find_by_xxx("beer").xxx').to eq("beer")
  end

  it "will correctly infer the model type from the inheritance column" do
    expect_evaluate_ruby('BaseClass.find_by_type("SubClass").class').to eq('SubClass')
    expect_evaluate_ruby('BaseClass.find_by_type(nil).class').to eq('BaseClass')
  end

  it "can have a has_many association" do
    expect_evaluate_ruby(HasMany.reflect_on_association(:belongs_to).klass.reflect_on_association(:has_many).klass).to eq(HasMany)
  end

  it "can have a has_one association" do
    expect_evaluate_ruby(HasOne.reflect_on_association(:belongs_to).klass.reflect_on_association(:has_one).klass).to eq(HasOne)
  end

  it "can override the class and foreign_key values when creating an association" do
    reflection = HasMany.reflect_on_association(:best_friends)
    expect_evaluate_ruby(reflection.klass).to eq(BelongsTo)
    expect_evaluate_ruby(reflection.association_foreign_key).to eq(:bf_id)
  end

  it "can have a scoping method" do
    expect_evaluate_ruby(Scoped.only_those_guys.respond_to? :all).to be_truthy
  end

  it "can type check parameters" do
    expect_evaluate_ruby(SubClass._react_param_conversion({attr1: 1, attr2: 2, type: "SubClass", id: 123}.to_n, :validate_only)).to be(true)
  end

  it "can type check parameters with native wrappers" do
    expect_evaluate_ruby(SubClass._react_param_conversion(Native({attr1: 1, attr2: 2, type: "SubClass", id: 123}.to_n), :validate_only)).to be(true)
  end

  it "will fail type checking if type does not match" do
    expect_evaluate_ruby(SubClass._react_param_conversion({attr1: 1, attr2: 2, type: nil, id: 123}.to_n, :validate_only)).to be_falsy
  end

  it "will convert a hash to an instance" do
    ar = SubClass._react_param_conversion({attr1: 1, attr2: 2, type: "SubClass", id: 123}.to_n)
    expect_evaluate_ruby(ar.attr1).to eq(1)
    expect_evaluate_ruby(ar.attr2).to eq(2)
    expect_evaluate_ruby(ar.id).to eq(123)
  end

end
