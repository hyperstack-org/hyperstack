<p align="center">
  <a href="http://ruby-hyperloop.io/" alt="Hyperloop" title="Hyperloop">
    <img src="https://github.com/ruby-hyperloop/ruby-hyperloop.io/blob/source/source/images/HyperRouter.png" width="150px"/>
  </a>
 </p>

<h1 align="center">
  HyperRouter
</h1>

<p align="center">
  HyperRouter allows you write and use the React Router in Ruby through Opal.
</p>


## Installation

Add this line to your application's Gemfile:
```ruby
gem 'hyper-router'
```
Or execute:
```bash
gem install hyper-router
```

Then add this to your components.rb:
```ruby
require 'hyper-router'
```

### Using the included source
Add this to your component.rb:
```ruby
require 'hyper-router/react-router-source'
require 'hyper-router'
```

### Using with NPM/Webpack
react-router has now been split into multiple packages, so make sure they are all installed
```bash
npm install react-router react-router-dom history --save
```

Add these to your webpack js file:
```javascript
ReactRouter = require('react-router')
ReactRouterDOM = require('react-router-dom')
History = require('history')
```

## Development

`bundle exec rake` runs test suite

## Contributing

1. Fork it ( https://github.com/ruby-hyperloop/reactrb-router/tree/hyper-router/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
