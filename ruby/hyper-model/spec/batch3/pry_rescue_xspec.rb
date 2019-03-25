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
    expect { ReactiveRecord::ServerDataCache[[],[], [["User", ["find", 1], "fake_attribute"]], nil] }.to raise_error(ActiveRecord::RecordNotFound)
  end

  context "will use pry rescue if it is defined" do

    before(:all) do
      pry = Class.new do
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
      Object.const_set("Pry", pry)
    end

    it "and it will still raise an error" do
      expect { ReactiveRecord::ServerDataCache[[],[], [["User", ["find", 1], "fake_attribute"]], nil] }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "but it will call Pry.rescued first" do
      ReactiveRecord::ServerDataCache[[],[], ["User", ["new", 10852], "fake_attribute"], nil] rescue nil
      expect(Pry.last_exception).to be_a(Exception)
    end

  end

end
