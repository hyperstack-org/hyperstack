#  HyperI18n

## HyperI18n gem

HyperI18n seamlessly brings Rails I18n into your Hyperloop application.


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
# config/locales/models/en.yml
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
# config/locales/views/en.yml
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
