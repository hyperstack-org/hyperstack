require 'spec_helper'

describe "isomorphic operations", js: true do
  before(:each) do
    isomorphic do
      class ServerFacts < HyperOperation
        regulate_uplink

        param :n, type: Integer, min: 0

        class << self
          attr_accessor :executed
          def fact(x)
            (x.zero?) ? 1 : x * fact(x-1)
          end
        end

        def execute
          ServerFacts.executed = true
          ServerFacts.fact(params.n)
        end
      end
    end
  end
  it "can run a method on the server" do
    expect_promise do
      ServerFacts(n: 5)
    end.to eq(ServerFacts.fact(5))
    expect(ServerFacts.executed).to be true
    expect_evaluate_ruby('ServerFacts.executed').to be nil
  end

  it "will pass server failures back" do
    expect_promise do
      ServerFacts(n: -1).fail { |exception| Promise.new.resolve(exception) }
    end.to eq('N is too small')
    expect_promise do
      ServerFacts(n: 10000000000).fail { |exception| Promise.new.resolve(exception) }
    end.to eq('stack level too deep')
  end

  it "will block bad uplinks" do
    ServerFacts.regulate_uplink { false }
    expect_promise do
      ServerFacts(n: 5).fail { |exception| Promise.new.resolve(exception) }
    end.to include('Hyperloop::AccessViolation')
  end
end
