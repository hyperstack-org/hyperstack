# Hyperstack 1.0

## Release goals

+ Hyperstack 1.0 based on Hyperloop edge


## Ruby version for Hyperstack

### Gemfile

Include this repo for development in your Gemfile can be done like this:

```ruby
gem 'hyper-component', :git => 'https://github.com/hyperstack-org/hyperstack', :glob => 'ruby/hyper-component/*.gemspec', branch: 'edge'
gem 'hyper-#{component_name}', :git => 'https://github.com/hyperstack-org/hyperstack', :glob => 'ruby/hyper-#{component_name}/*.gemspec', branch: 'edge'
```
