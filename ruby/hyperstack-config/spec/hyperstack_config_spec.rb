require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe 'Hyperstack Auto Config', js: true do

  after(:each) do
    Timecop.return
  end

  it 'will find and load everything and expand erb files and set Hyperstack.env' do
    `rm -rf spec/test_app/tmp/cache`
    Timecop.freeze
    visit '/'
    expect(evaluate_script("Opal.Test.$const_get('TIME')")).to eq("#{Time.now}")
    expect(evaluate_script("Opal.INFLECTORS_LOADED")).to be_truthy
    %w[test production staging development etc].each do |env|
      expect(evaluate_script("Opal.Hyperstack.$env().$send('#{env}?')")).to eq(Rails.env.send(:"#{env}?"))
      expect(Hyperstack.env).to eq(Rails.env)
    end
  end

end
