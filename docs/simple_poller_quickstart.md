### Simple Poller Quickstart

The easiest push transport is the built-in simple poller.  This is great for demos or trying out Hyperloop but because it is constantly polling it is not suitable for production systems or any kind of real debug or test activities.

#### 1 Add the HyperLoop gems to your Rails app

If you have not already installed the `hyper-component` and `hyper-model` gems, then do so now using the [hyper-rails](https://github.com/ruby-hyperloop/hyper-rails) gem.

- add `gem 'hyper-rails'` to your gem file (in the development section)
- run `bundle install`
- run `rails g hyperloop:install --all` (make sure to use the --all option)
- run `bundle update`

#### 2 Set the transport

Once you have Hyperloop installed then add this initializer:
```ruby
#config/initializers/hyperloop.rb
Hyperloop.configuration do |config|
  config.transport = :simple_poller
  # options
  # config.opts = {
  #   seconds_between_poll: 5, # default is 0.5 you may need to increase if testing with Selenium
  #   seconds_polled_data_will_be_retained: 1.hour  # clears channel data after this time, default is 5 minutes
  # }
end
```

#### 3 Try It Out  

TODO add try_it_out partial
