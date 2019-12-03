# Contributing to Hyperstack

We welcome and encourage contribution and would be delighted if you participated in this project.  
If you're new to Hyperstack but have experience with Ruby (and Rails) and would like to contribute then start with the [ToDo tutorial](https://docs.hyperstack.org/tutorial)
that way you understand the basic capabilities and lingo of Hyperstack.

Next would be to start an experimental project that's based on the *edge* Hyperstack codebase.  
If you just want to build a project with Hyperstack without contributing to Hyperstack itself you're better of sticking to released versions of Hyperstack.
But presuming you do want to contribute you can change you `Gemfile` in the following way to get your project on *edge*.

```ruby
git 'https://github.com/hyperstack-org/hyperstack', branch: 'edge', glob: 'ruby/*/*.gemspec' do
  gem 'rails-hyperstack'
  gem 'hyper-component'
  gem 'hyper-i18n'
  gem 'hyper-model'
  gem 'hyper-operation'
  gem 'hyper-router'
  gem 'hyper-state'
  gem 'hyperstack-config'
  gem 'hyper-trace', group: :development
end

gem 'foreman', group: :development
```
The *edge* branch is the latest work in progress, where specs (automated tests) are passing, for the individual gem.  
The difference between *edge* and *master*, is that *master* guarantees that all specs across all gems pass, plus *master* is the branch from which new versions are released.  

With this configuration you can track development of Hyperstack itself and discuss changes with the other developers.  

In the following sections we explain how to make different types of contributions.
 - Contributing code to Hyperstack
   - Running tests for your code
   - Adding your own tests
 - Improving the Hyperstack documentation
 - If you think you can improve the website
 - When you find a possible bug
 - Fixing a bug

## Contributing code to Hyperstack

With the `Gemfile` configuration above you can track Hyperstack development. But you can't contribute code.

For that you need to `git clone https://github.com/hyperstack-org/hyperstack.git`  
Cd into the directory `cd hyperstack`  
And change to the *edge* branch: `git checkout edge` (*edge* is the default branch but just to be sure).

This gives you a local copy of the Hyperstack codebase on your system.  
You will have to reconfigure the `Gemfile` of your own website project with a [filesystem path](https://bundler.io/gemfile.html) so it uses this local Hyperstack copy.  

```
gem 'rails-hyperstack',  path: '~/path/to/hyperstack/ruby/rails-hyperstack'
gem 'hyper-component',   path: '~/path/to/hyperstack/ruby/hyper-component'
gem 'hyper-i18n',        path: '~/path/to/hyperstack/ruby/hyper-i18n'
gem 'hyper-model',       path: '~/path/to/hyperstack/ruby/hyper-model'
gem 'hyper-operation',   path: '~/path/to/hyperstack/ruby/hyper-operation'
gem 'hyper-router',      path: '~/path/to/hyperstack/ruby/hyper-router'
gem 'hyper-state',       path: '~/path/to/hyperstack/ruby/hyper-state'
gem 'hyperstack-config', path: '~/path/to/hyperstack/ruby/hyperstack-config'
gem 'hyper-trace',       path: '~/path/to/hyperstack/ruby/hyper-trace', group: :development
#gem 'hyper-store',       path: '~/path/to/hyperstack/ruby/hyper-store' # Extra (legacy?)
```

Or use `bundle config local.GEM_NAME /path/to/hyperstack` as described [here](https://rossta.net/blog/how-to-specify-local-ruby-gems-in-your-gemfile.html). But I would recommend the Gemfile with a local path approach.  
Use `bundle config --delete local.GEM_NAME` to remove a `bundle config local` configuration.

This setup provides a local Hyperstack development environment. You're now able to fix bugs and create new features within the Hyperstack code itself.  
If your improvements could be interesting to others then push it to Github and create a pull request.
Then keep reminding the existing developers that you would like your code pulled into the Hyperstack repository.
When they find the time to look at it and like your code they will kindly ask you to also write some specs before your code is merged. That's a good thing, your code is considered valuable, but does require those tests.
Please understand that your code can also be rejected because it has security issues, is slow, hard to maintain or buggy (among other things).
Nobody likes it when this happens, but it can happen. If what you're trying to achieve is making sense then please keep at it.
If you have wild out of the box ideas that would not match Hyperstack then please use the power to fork away and prove your ideas independently.
But Hyperstack and Opal are quite happily pushing boundaries, so we might like your crazy ideas.

**Pro tip:** Talk trough your plans for changes before writing a lot of code. Push a few small fixes before starting mayor rewrites.

Hyperstack's [license is MIT](https://github.com/hyperstack-org/hyperstack/blob/edge/LICENSE). All code contributions must be under this license. If code is submitted under a different open source license then this must be explicitly stated. Preferably with an explanation why it can't be MIT.

### Running tests for your code

Hyperstack has a comprehensive automated test system. Changes to code must be accompanied with the necessary tests.  
This is how you setup the test environment on your local development system:

 - You do the `git clone https://github.com/hyperstack-org/hyperstack.git` as before.  
 - Now you enter the gem you would like to run the tests for. Lets say you change directory to the hyper-model gem `cd ~/path/to/hyperstack/ruby/hyper-model`
 - Optionally but recommended: Create a RVM environment by adding the `.ruby-gemset` and `.ruby-version` files, run `cd .` to reload RVM.
 - Install bundler `gem install bundler` then run `bundle install` to pull in the gems needed for testing.
 - Then you have to setup the test environment by running `rake spec:prepare`, this creates the test database and tables.

After this call `rspec spec` to run the tests.

If all test pass you know your changes to the Hyperstack code did not break any existing functionality.  
Please understand that tests can sometimes be flaky, re-run tests if needed. Sometimes it's just the phase of the moon.

### Adding your own tests

Cleaning up and improving the existing tests is a great and "safe" way to contribute and get experience with the Hyperstack codebase.  

**TODO:** Pointers about directory structure.

 - Test one thing at a time, don't write one large test.
 - Check the before state, call the code you want to test, check if the before state has changed to the expected state.
 - Test the interface, the internals of the implementation should keep some flexibility.
 - Watch out with testing things that use Date/Time, you don't want your test to fail when it's run on the 29th of February or when run in a different timezone.
 - Don't check if `string1.include?(string2)` if string2 can be an empty string, like "". As that would pass.
 - Tests are a development tool, flaky or slow tests that don't cover enough have a negative value.
 - Test your feature with different types of input (nil, empty string, empty array, false, zero, negative dates). Don't test with every day of the year if it exesersizes the same codepath as with the other dates.
 
## Improving the Hyperstack documentation

Each page on [the website](https://hyperstack.org) has an ***Improve this page*** button which will allow you to edit the underlying markdown file on Github and create a ***pull request***. This is to make it as easy as possible to contribute to the documentation.
And make small fixes quickly.

If you're planning on making sustained contributions to the documentation we would suggest to do a `git clone https://github.com/hyperstack-org/hyperstack.git` as documented above with code contributions.
Most documentation is written in .md files under the docs directory and can be edited with dedicated markdown editors or even plain text editors.  
Push your changes and create a ***pull request*** as if it's a code contribution.

## If you think you can improve the website

The website's code can be found in [this repository](https://github.com/hyperstack-org/website).  
By running `git clone https://github.com/hyperstack-org/website.git` you can check out your own copy.  
Please note that this repository does not contain the documentation. The website pulls the most recent markdown files from the *edge* hyperstack repository.

Before you write code to change the website, please create an issue describing your plans and reach out to us in [Slack](https://join.slack.com/t/hyperstack-org/shared_invite/enQtNTg4NTI5NzQyNTYyLWQ4YTZlMGU0OGIxMDQzZGIxMjNlOGY5MjRhOTdlMWUzZWYyMTMzYWJkNTZmZDRhMDEzODA0NWRkMDM4MjdmNDE) chat. Our goal for this site is that it acts as a showcase for all that Hyperstack can do, so your creativity is very welcome.

## When you find a possible bug

You can ask on [Slack chat](https://join.slack.com/t/hyperstack-org/shared_invite/enQtNTg4NTI5NzQyNTYyLWQ4YTZlMGU0OGIxMDQzZGIxMjNlOGY5MjRhOTdlMWUzZWYyMTMzYWJkNTZmZDRhMDEzODA0NWRkMDM4MjdmNDE) if you're making a mistake or actually found a bug. (get a account via the "Join Slack" button on the [homepage](https://hyperstack.org))  
Also check the [GitHub issue list](https://github.com/hyperstack-org/hyperstack/issues) and if you don't find it mentioned there, please create an issue.  
If you can reproduce the problem in a branch you push to GitHub we will love you even more.

We also have a [feature matrix](https://github.com/hyperstack-org/hyperstack/blob/edge/docs/feature_matrix.md), which is an attempt to list known issues and the current status.
Having people expanding and maintaining this table would be excellent.

## Fixing a bug

Please ask in [Slack chat](https://join.slack.com/t/hyperstack-org/shared_invite/enQtNTg4NTI5NzQyNTYyLWQ4YTZlMGU0OGIxMDQzZGIxMjNlOGY5MjRhOTdlMWUzZWYyMTMzYWJkNTZmZDRhMDEzODA0NWRkMDM4MjdmNDE) if you need pointers. There is always tons to do so we would appreciate the help.  
You can see the list of GitHub issues labelled '[Help Wanted](https://github.com/hyperstack-org/hyperstack/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22)'
or look at the [feature matrix](https://github.com/hyperstack-org/hyperstack/blob/edge/docs/feature_matrix.md) for things that have the status 'bugged'.