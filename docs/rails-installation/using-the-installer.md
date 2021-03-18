## Installing HyperStack

* add `gem 'rails-hyperstack', "~> 1.0.alpha1.0"` to your gem file
* run `bundle install`
* run `bundle exec rails hyperstack:install`

> Note: if you want to use the unreleased edge branch your gem specification will be:
>
> ```ruby
> gem 'rails-hyperstack',
>      git: 'git://github.com/hyperstack-org/hyperstack.git',
>      branch: 'edge',
>      glob: 'ruby/*/*.gemspec'
> ```

### Start the Rails app

* `bundle exec foreman start` to start Rails and the Hotloader
* Navigate to `http://localhost:5000/`

You will see an empty page with the word "App" displayed.

Open your editor and find the file `/app/hyperstack/components/app.rb`

Change the `'App'` to `'Hello World'` and save the file.

You should see the page on the browser change to "Hello World"

You are in business!

### Installer Options

You can control what gets installed with the following options:

```
bundle exec rails hyperstack:install:webpack          # just add webpack
bundle exec rails hyperstack:install:skip-webpack     # all but webpack
bundle exec rails hyperstack:install:hyper-model      # just add hyper-model
bundle exec rails hyperstack:install:skip-hyper-model # all but hyper-model
bundle exec rails hyperstack:install:hotloader        # just add the hotloader
bundle exec rails hyperstack:install:skip-hotloader   # skip the hotloader
```

> Note that the `:webpack` and `:skip-webpack` options control whether the installer will
add the webpacker Gem.  If webpacker is already installed in the Gemfile then the
installer will always integrate with webpacker.
