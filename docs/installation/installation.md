# Installation

The Hyperstack Installation guide has not been written yet. Please see the Upgrading section for information.

## Notes for deploying to Heroku

+ `heroku create`
+ `heroku buildpacks:set heroku/nodejs`
+ `heroku buildpacks:add heroku/ruby`

In `production.rb` change

+ `config.assets.js_compressor = :uglifier` to

+ `config.assets.js_compressor = Uglifier.new(
    :harmony => true
  )`
