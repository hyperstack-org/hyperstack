require 'spec_helper'

describe "resetting contexts" do
  after(:all) do
    Hyperstack::Context.instance_variable_set(:@context, nil)
  end

  it "resets everything nicely on the server" do
    Hyperstack::Context.reset!
    stub_const 'Operation', Class.new(Hyperstack::Operation)
    expect(Operation).to receive(:receiver).once.with({bar: 'goodgood'})
    Operation.class_eval do
      param :foo
      validate { false }
      step { abort! }
      on_dispatch { receiver }
    end
    expect(Operation.run(bar: 'good')).not_to be_resolved
    Hyperstack::Context.reset!
    Operation.class_eval do
      param :bar
      validate { params.bar == 'good' }
      step { params.bar = params.bar * 2 }
      on_dispatch { |params| receiver(params.to_h) }
    end
    expect(Operation.run(bar: 'good')).to be_resolved
  end

  it "resets operations nicely on the client", js: true do
    expect_promise do
      Hyperstack::Context.reset!
      class Operation < Hyperstack::Operation
        param :foo
        validate { false }
        step { abort! }
        on_dispatch { receiver }
      end
      Hyperstack::Context.reset!
      class Operation < Hyperstack::Operation
        param :bar
        validate { params.bar == 'good' }
        step { params.bar * 2 }
      end
      Operation.run(bar: 'good')
    end.to eq('goodgood')
  end

  it "does not reset any predefined boot receivers", js: true do
    on_client do
      class Store < Hyperstack::Store
        class << self
          attr_reader :boot_calls
          attr_reader :another_receiver_calls
          def booted
            puts "  booted called"
            @boot_calls ||= 0
            @boot_calls += 1
          end
          def another_receiver
            puts "  receiver called"
            @another_receiver_calls ||= 0
            @another_receiver_calls += 1
          end
        end
        receives Hyperstack::Application::Boot, :booted
      end
      puts ">>resetting"
      Hyperstack::Context.reset!(reboot = nil)
      class Store < Hyperstack::Store
        receives Hyperstack::Application::Boot, :another_receiver
      end
    end
    evaluate_ruby("puts '>>booting'") # do a separate evaluation to get initial boot completed
    evaluate_ruby do
      puts '>>resetting again'
      Hyperstack::Context.reset!(nil)
      puts '>>booting again'
      Hyperstack::Application::Boot.run
    end
    expect_evaluate_ruby('Store.boot_calls').to eq(2)
    expect_evaluate_ruby('Store.another_receiver_calls').to eq(1)
  end
end
