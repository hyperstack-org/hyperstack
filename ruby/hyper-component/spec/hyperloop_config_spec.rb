require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe 'Hyperloop Auto Config', js: true do
  # note most config functionality is coverered when running other gem specs.
  it 'will find and load everything and expand erb files' do
    `rm -rf spec/test_app/tmp/cache`
    Timecop.freeze
    expect_evaluate_ruby('TestIt::TIME').to eq("#{Time.now}")
    Timecop.return
  end
end
