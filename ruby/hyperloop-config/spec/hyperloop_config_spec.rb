require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe 'Hyperloop Auto Config', js: true do

  after(:each) do
    Timecop.return
  end

  it 'will find and load everything and expand erb files and set Hyperloop.env' do
    `rm -rf spec/test_app/tmp/cache`
    Timecop.freeze
    visit '/'
    expect(evaluate_script("Opal.Test.$const_get('TIME')")).to eq("#{Time.now}")
    %w[test production staging development etc].each do |env|
      expect(evaluate_script("Opal.Hyperloop.$env().$send('#{env}?')")).to eq(Rails.env.send(:"#{env}?"))
      expect(Hyperloop.env).to eq(Rails.env)
    end
  end

end
