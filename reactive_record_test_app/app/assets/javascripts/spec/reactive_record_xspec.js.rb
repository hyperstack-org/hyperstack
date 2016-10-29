require 'spec/spec_helper'
require 'user'


  
describe "Reactive Record" do
  
  after(:each) { React::API.clear_component_class_cache }
  
  # uncomment if you are having trouble with tests failing.  One non-async test must pass for things to work
  
  # describe "a passing dummy test" do
  #   it "passes" do
  #     expect(true).to be(true)
  #   end 
  # end
  
  describe "reactive_record basic api" do
    
    rendering("a simple component") do
      div {"hello"}
    end.should_immediately_generate do |component|
      component.html == "hello"
    end
    
    rendering("a find_by query") do
      User.find_by_email("mitch@catprint.com").email
    end.should_immediately_generate do 
      html == "mitch@catprint.com"
    end
    
    it "should yield the same find_by result if called twice" do
      ar1 = User.find_by_email("mitch@catprint.com")
      ar2 = User.find_by_email("mitch@catprint.com")
      expect(ar1.equal?(ar2)).to be(true)
    end
    
    
  end
  
end
  
