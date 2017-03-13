require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe 'Hyperloop Auto Config', js: true do

  after(:each) do
    Timecop.return
  end

  it 'will find and load everything and expand erb files' do
    `rm -rf spec/test_app/tmp/cache`
    Timecop.freeze
    visit '/'
    expect(evaluate_script("Opal.Test.$const_get('TIME')")).to eq("#{Time.now}")
  end

end
