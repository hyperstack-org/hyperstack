# Using Hyperspec with Rack

Hyperspec will run with Rails out of the box, but you can also use Hyperspec with any Rack application, with just a little more setup.  For example here is a sample configuration setup with Sinatra:

```ruby
# Gemfile
...

gem "sinatra"
gem "rspec"
gem "pry"
gem "opal"
gem "opal-sprockets"
gem "rack"
gem "puma"
group :test do
  # gem 'hyper-spec', '~> 1.0.alpha1.0'
  # or to use edge:
  gem 'hyper-spec',
      git: 'git://github.com/hyperstack-org/hyperstack.git',
      branch: 'edge',
      glob: 'ruby/*/*.gemspec'
end
```

```ruby
# spec/spec_helper.rb

require "bundler"
Bundler.require
ENV["RACK_ENV"] ||= "test"

# require your application files as needed
require File.join(File.dirname(__FILE__), "..", "app.rb")

# bring in needed support files
require "rspec"
require "rack/test"
require "hyper-spec/rack"

# assumes your sinatra app is named app
Capybara.app = HyperSpecTestController.wrap(app: app)

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false
```

### Details

The interface between Hyperspec and your application environment is defined by the `HyperspecTestController` class.  This file typically includes a set of helper methods from `HyperSpec::ControllerHelpers`, which can then be overridden to give whatever behavior your specific framework needs.  Have a look at the `hyper-spec/rack.rb` and `hyper-spec/controller_helpers.rb` files in the Hyperspec gem directory.

### Example

A complete (but very simple) example is in this repos `ruby/examples/misc/sinatra_app` directory
