require 'spec_helper'

describe 'Kernel#sleep redefinition', js: true do
  it "returns a promise that sleeps for the specified time" do
    [1, 3].each do |t|
      start_time = Time.parse(evaluate_ruby("Time.now"))
      evaluate_promise "sleep(#{t})"
      expect(Time.now-start_time).to be_between(t, t+1)
    end
  end

  it "can return the value specified by a block" do
    expect_promise("sleep(1) { 'hello' }").to eq('hello')
  end
end
