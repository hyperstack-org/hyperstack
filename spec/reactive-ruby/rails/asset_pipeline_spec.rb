require 'spec_helper'

RSpec.describe 'test_app generator' do
  it "does not interfer with asset precompilation" do
    cmd = "cd spec/test_app; BUNDLE_GEMFILE=#{ENV['REAL_BUNDLE_GEMFILE']} bundle exec rails assets:precompile"
    expect(system(cmd)).to be_truthy
    "cd spec/test_app; BUNDLE_GEMFILE=#{ENV['REAL_BUNDLE_GEMFILE']} bundle exec rails assets:clobber"
  end
end
