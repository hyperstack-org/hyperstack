require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe 'Active Support Helpers', js: true do
  it "Array#index_with" do
    on_client do
      Payment = Struct.new(:price)
      class GenericEnumerable
        include Enumerable
        def initialize(values = [1, 2, 3])
          @values = values
        end
        def each
          @values.each { |v| yield v }
        end
      end
      def payments
        GenericEnumerable.new([ Payment.new(5), Payment.new(15), Payment.new(10) ])
      end
    end

    expect_evaluate_ruby do
      { Payment.new(5) => 5, Payment.new(15) => 15, Payment.new(10) => 10 } == payments.index_with(&:price)
    end.to be_truthy
    expect_evaluate_ruby do
      %i( title body ).index_with(nil)
    end.to eq({ title: nil, body: nil }.with_indifferent_access)
    expect_evaluate_ruby do
      %i( title body ).index_with([])
    end.to eq({ title: [], body: [] }.with_indifferent_access)
    expect_evaluate_ruby do
      %i( title body ).index_with({})
    end.to eq({ title: {}, body: {} }.with_indifferent_access)
    expect_evaluate_ruby do
      Enumerator == payments.index_with.class
    end.to be_truthy
    expect_evaluate_ruby do
      payments.index_with.size
    end.to be_nil
    expect_evaluate_ruby do
      (1..42).index_with.size
    end.to eq 42
  end

  it "Enumerable#extract!" do
    # interesting could not find the test case in rails, this is from the comments:
    on_client do
      def numbers
        @numbers ||= [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
      end
    end
    expect_evaluate_ruby do
      odd_numbers = numbers.extract! { |number| number.odd? }
    end.to eq [1, 3, 5, 7, 9]
    expect_evaluate_ruby do
      numbers.extract! { |number| number.odd? }
      numbers
    end.to eq [0, 2, 4, 6, 8]
  end
end
