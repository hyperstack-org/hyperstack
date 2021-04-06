require 'spec_helper'

describe 'calling class initialize method', :js do
  before(:each) do
    isomorphic do
      class ClassStore
        include Hyperstack::State::Observable
        class << self
          attr_reader :initialized
          def initialize
            @initialized = !@initialized && self
          end
        end
      end

      class ClassSubStore < ClassStore
        class << self
          attr_reader :initialized
          def initialize
            @initialized = !@initialized && self
          end
        end
      end

      class ClassSubNoInit < ClassStore
      end

      class SubGumStore < ClassStore
        include Hyperstack::State::Observable
        class << self
          attr_reader :initialized
          def initialize
            @initialized = !@initialized && self
          end
        end
      end
    end
  end

  it "the store will receive a class level initialize (client)" do
    expect { ClassStore.initialized }.on_client_to eq(ClassStore.to_s)
    expect { ClassSubStore.initialized }.on_client_to eq(ClassSubStore.to_s)
    expect { SubGumStore.initialized }.on_client_to eq(SubGumStore.to_s)
  end

  it "the store will receive a class level initialize (server)" do
    Hyperstack::Application::Boot.run

    expect(ClassStore.initialized).to eq(ClassStore)
    expect(ClassSubStore.initialized).to eq(ClassSubStore)
    expect(SubGumStore.initialized).to eq(SubGumStore)
  end
end
