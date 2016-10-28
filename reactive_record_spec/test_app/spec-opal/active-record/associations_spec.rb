require 'spec_helper'
#require 'user'
#require 'todo_item'


class Thing < ActiveRecord::Base
  belongs_to :bucket
end

class Bucket < ActiveRecord::Base
  has_many :things
end

class OtherThing < ActiveRecord::Base
  has_many :things, through: :thing_group
end

describe "ActiveRecord" do
  
  after(:each) { React::API.clear_component_class_cache }
  
  # uncomment if you are having trouble with tests failing.  One non-async test must pass for things to work
  
  # describe "a passing dummy test" do
  #   it "passes" do
  #     expect(true).to be(true)
  #   end 
  # end
  
  
  describe "Association Reflection" do
    
    it "knows the foreign key of a belongs_to relationship" do
      expect(Thing.reflect_on_association(:bucket).association_foreign_key).to eq(:bucket_id)
    end
    
    it "knows the foreign key of a has_many relationship" do
      expect(Bucket.reflect_on_association(:things).association_foreign_key).to eq(:bucket_id)
    end
    
    it "knows the attribute name" do
      expect(Bucket.reflect_on_association(:things).attribute).to eq(:things)
    end
    
    it "knows the associated klass" do
      expect(Bucket.reflect_on_association(:things).klass).to eq(Thing)
    end
        
    it "knows the macro" do
      expect(Bucket.reflect_on_association(:things).macro).to eq(:has_many)
    end
    
    it "knows the inverse" do
      expect(Bucket.reflect_on_association(:things).inverse_of).to eq(:bucket)
    end

    it "knows if the association is a collection" do
      expect(Bucket.reflect_on_association(:things).collection?).to be_truthy
    end
    
    it "knows if the association is not a collection" do
      expect(Thing.reflect_on_association(:bucket).collection?).to be_falsy
    end
    
    it "knows the associated klass of a has_many_through relationship" do
      expect(OtherThing.reflect_on_association(:things).klass).to eq(Thing)
    end
    
    it "knows a has_many_through is a collection" do
      expect(OtherThing.reflect_on_association(:things).collection?).to be_truthy
    end
    
    it "does not return a inverse for a has_many_through collection" do
      expect(OtherThing.reflect_on_association(:things).inverse_of).to be_nil
    end
    
  end
  
end