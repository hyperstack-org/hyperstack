require 'spec_helper'

if ruby?
RSpec.describe 'test_app generator' do
  it "does not interfer with asset precompilation" do
    env = { "BUNDLE_GEMFILE" => ENV['BUNDLE_GEMFILE'] }
    expect(system(env, "cd spec/test_app; bundle exec rake assets:precompile")).to be_truthy
  end
end
end
