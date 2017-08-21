#  HyperI18n


## HyperI18n gem

HyperI18n seamlessly brings Rails I18n into your Hyperloop application.


## Documentation and Help

+ Please see the [ruby-hyperloop.io](http://ruby-hyperloop.io/) website for documentation.
+ Join the Hyperloop [gitter.io](https://gitter.im/ruby-hyperloop/chat) chat for help and support.


## Installation and Setup

1. Add `gem 'hyper-i18n', git: 'https://github.com/ruby-hyperloop/hyper-i18n.git'` to your `Gemfile`
2. Install the Gem: `bundle install`
3. Add `require 'hyper-i18n'` to your components manifest


## Note!

This gem is in it's very early stages, and only a handful of the API has been implemented.
Contributions are very welcome!

### Usage

Hyper-I18n brings in the standard ActiveSupport API.


#### ActiveRecord Models

The methods `Model.model_name.human` and `Model.human_attribute_name` are available:

```yaml
# config/locals/models/en.yml
en:
  activerecord:
    models:
      user: 'Customer'
    attributes:
      name: 'Name'
```
```ruby
User.model_name.human
# 'Customer'

User.human_attribute_name(:name)
# 'Name'
```

#### Views

Hyper-I18n makes available the method `t` to components, just as ActiveSupport does for views.
It also implements the same lazy-loading pattern,
so if you name space your locale file the same as your components, it will just work:

```yaml
# config/locals/views/en.yml
en:
  users:
    show:
      title: 'Customer View'
```
```ruby
module Users
  class Show < Hyperloop::Component
    render do
      H1 { t(:title) }
    end
  end
end

# <h1>Customer View</h1>
```

### Server Rendering

HyperI18n is fully compatible with server rendering!
All translations are also sent to the client, so as to bypass fetching/rendering again on the client.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby-hyperloop/hyper-i18n.
This project is intended to be a safe, welcoming space for collaboration,
and contributors are expected to adhere to the [Code of Conduct](https://github.com/ruby-hyperloop/hyper-operation/blob/master/CODE_OF_CONDUCT.md) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
