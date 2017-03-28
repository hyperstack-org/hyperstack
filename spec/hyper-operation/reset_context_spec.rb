require 'spec_helper'

describe "resetting contexts" do
  after(:all) do
    Hyperloop::Context.instance_variable_set(:@context, nil)
  end

  it "resets everything nicely on the server" do
    Hyperloop::Context.reset!
    stub_const 'Operation', Class.new(Hyperloop::Operation)
    expect(Operation).to receive(:receiver).once.with({bar: 'goodgood'})
    Operation.class_eval do
      param :foo
      validate { false }
      step { abort! }
      on_dispatch { receiver }
    end
    expect(Operation.run(bar: 'good')).not_to be_resolved
    Hyperloop::Context.reset!
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
      Hyperloop::Context.reset!
      class Operation < Hyperloop::Operation
        param :foo
        validate { false }
        step { abort! }
        on_dispatch { receiver }
      end
      Hyperloop::Context.reset!
      class Operation < Hyperloop::Operation
        param :bar
        validate { params.bar == 'good' }
        step { params.bar * 2 }
      end
      Operation.run(bar: 'good')
    end.to eq('goodgood')
  end

  it "does not reset any predefined boot receivers", js: true do
    on_client do
      class Store < Hyperloop::Store
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
        receives Hyperloop::Application::Boot, :booted
      end
      puts ">>resetting"
      Hyperloop::Context.reset!(reboot = nil)
      class Store < Hyperloop::Store
        receives Hyperloop::Application::Boot, :another_receiver
      end
    end
    evaluate_ruby("puts '>>booting'") # do a separate evaluation to get initial boot completed
    evaluate_ruby do
      puts '>>resetting again'
      Hyperloop::Context.reset!(nil)
      puts '>>booting again'
      Hyperloop::Application::Boot.run
    end
    expect_evaluate_ruby('Store.boot_calls').to eq(2)
    expect_evaluate_ruby('Store.another_receiver_calls').to eq(1)
  end
end
