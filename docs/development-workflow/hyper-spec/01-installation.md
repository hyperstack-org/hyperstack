# HyperSpec Installation

Add `gem 'hyper-spec'` to your Gemfile in the usual way.  
Typically in a Rails app you will add this in the test section of your Gemfile:

```ruby
group :test do
  gem 'hyper-spec', '~> 1.0.alpha1.0'
end
```

Make sure to `bundle install`.

> Note: if you want to use the unreleased edge branch your hyper-spec gem specification will be:
>
> ```ruby
> gem 'hyper-spec',
>      git: 'git://github.com/hyperstack-org/hyperstack.git',
>      branch: 'edge',
>      glob: 'ruby/*/*.gemspec'
> ```

HyperSpec is integrated with the `pry` gem for debugging, so it is recommended to add the `pry` gem as well.

HyperSpec will also use the `timecop` gem if present to allow you to control and synchronize time on the server and the client.

A typical spec_helper file when using HyperSpec will look like this:

```ruby
# spec_helper.rb
require 'hyper-spec'
require 'pry'  # optional

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path('../test_app/config/environment', __FILE__)

require 'rspec/rails'
require 'timecop' # optional

# any other rspec configuration you need
# note HyperSpec will include chrome driver for providing the client
# run time environment
```

To load the webdriver and client environment your spec should have the
`:js` flag set:

```ruby
# the js flag can be set on the entire group of specs, or a context
describe 'some hyper-specs', :js do
  ...
end

# or for an individual spec
  it 'an individual hyper-spec', :js do
    ...
  end
```
