require 'spec_helper'

# this spec makes trouble, becasue if the assets wont get deleted, the app will use
# the precompiled assets suring testing, whcih interferes with dynamically created code
describe 'test_app generator' do
  it "does not interfere with asset precompilation", skip: 'spec not working' do
    cmd = "cd spec/test_app; BUNDLE_GEMFILE=#{ENV['REAL_BUNDLE_GEMFILE']} bundle exec rails assets:precompile"
    expect(system(cmd)).to be_truthy
  end
end

describe 'assets:clobber' do
  it "remove precompiled assets so tests use recent assets", skip: 'spec not working' do
    cmd = "cd spec/test_app; BUNDLE_GEMFILE=#{ENV['REAL_BUNDLE_GEMFILE']} bundle exec rails assets:clobber"
    expect(system(cmd)).to be_truthy
  end
end
