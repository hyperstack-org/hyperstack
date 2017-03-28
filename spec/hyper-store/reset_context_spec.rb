require 'spec_helper'

describe "resetting contexts" do

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
