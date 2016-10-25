require 'spec_helper'

describe "ServerDataCache" do

  before(:all) do
    @current_pry_definition = Object.const_get("Pry") if defined? Pry
    @current_pry_rescue_definition = Object.const_get("PryRescue")  if defined? PryRescue
  end

  after(:all) do
    Object.const_set("Pry", @current_pry_definition) if @current_pry_definition
    Object.const_set("PryRescue", @current_pry_definition) if @current_pry_rescue_definition
  end

  it "behaves normally if there is no pry rescue" do
    binding.pry
    expect(ReactiveRecord::ServerDataCache[[],[], ["User", ["new", 10852], "fake_attribute"], nil]).to raise_error
  end

  context "will use pry rescue if it is defined" do

    before(:all) do
      dummy_pry = Class.new do
        def self.rescue
          yield
        end
        def self.rescued(e)
          @last_exception = e
        end
        def self.last_exception
          @last_exception
        end
      end
      Object.const_set("PryRescue", true)
      Object.const_set("Pry", dummy_pry)
    end

    it "and it will still raise an error" do
      expect(ReactiveRecord::ServerDataCache[[],[], ["User", ["new", 10852], "fake_attribute"], nil]).to raise_error
    end

    it "and it will call Pry.rescued" do
      ReactiveRecord::ServerDataCache[[],[], ["User", ["new", 10852], "fake_attribute"], nil] rescue nil
      expect(dummy_pry.last_exception).to be_a(Exception)
    end

  end

end
