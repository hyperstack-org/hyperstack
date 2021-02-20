# Hyperstack
[![Build Status](https://travis-ci.com/hyperstack-org/hyperstack.svg?branch=edge)](https://travis-ci.com/hyperstack-org/hyperstack)

This is the edge branch - the system is stable, and there are approx 1000 test specs passig.  For current status on development see [current status.](https://github.com/hyperstack-org/hyperstack/blob/edge/current-status.md)

Hyperstack is a Ruby-based DSL and modern web toolkit for building spectacular, interactive web applications fast!

+ **One language** throughout the client and server. All Ruby code is compiled by [Opal](https://opalrb.com/) into JavaScript automatically.
+ Webpacker and Yarn tooling for a **modern, fast hot-reloader build environment with Ruby source maps**.
+ A well documented and stable Ruby DSL for wrapping **React** and **ReactRouter** as well as **any** JavaScript library or component. No need to learn JavaScript!
+ **Isomorphic Models with bi-directional data** so you can access your models as if they were on the client.

All that means you can write simple front-end code like this:

```ruby
class GoodBooksToRead < HyperComponent
  render(UL) do
    Book.good_books.each do |book|
      LI { "Read #{book.name}" }.on(:click) { display book } if book.available?
    end
  end
end
```

In the code above, if the `good_books` scope changed (even on the server), the UI would update automatically. That's the magic of React and Isomorphic Models with bi-directional data at work!

## Website and documentation

Please see the documentation site for full documentation, or find the same content in the [/docs](/docs) folder in this repo if you prefer.

+ Website: [hyperstack.org](https://hyperstack.org)
+ Docs: [docs.hyperstack.org](https://docs.hyperstack.org/)

## Setup and installation

You can be up and running in **less than 5 minutes**. Just follow the simple setup guide for a new Rails application all correctly configured and ready to go with Hyperstack.

+ [Setup and Installation docs](https://docs.hyperstack.org/installation/man-installation)

## Community and support

Hyperstack is supported by a friendly, helpful community, both for users, and contributors. We welcome new people, please reach out and say hello.

+ [Join](https://join.slack.com/t/hyperstack-org/shared_invite/enQtNTg4NTI5NzQyNTYyLWQ4YTZlMGU0OGIxMDQzZGIxMjNlOGY5MjRhOTdlMWUzZWYyMTMzYWJkNTZmZDRhMDEzODA0NWRkMDM4MjdmNDE) our Slack group
+ After you have joined there is a shortcut at https://hyperstack.org/slack

### StackOverflow Questions

Please ask technical questions on StackOverflow as the answers help people in the future. We use the `hyperstack` tag, but also add `ruby-on-rails`, `ruby` and `react-js` tags to get this project exposed to a broader community.

+ Please ask questions here: https://hyperstack.org/question
+ All the `hyperstack` tagged questions are here: https://hyperstack.org/questions

## Roadmap

Hyperstack is evolving; we are improving it all the time. As much as we love Ruby today, we see ourselves embracing new languages in the future. [Crystal](https://crystal-lang.org/) perhaps? We are also watching [Wasm](https://webassembly.org/) carefully.

Please see the  [ROADMAP][] file for more information.

[roadmap]: ROADMAP.md
[current status]: current-status.md

## Contributing

If you would like to help, please read the [CONTRIBUTING][] file for suggestions.

[contributing]: CONTRIBUTING.md

## Links

+ Rubygems: https://rubygems.org/profiles/hyperstack
+ Travis: https://travis-ci.org/hyperstack-org
+ Website edge: https://edge.hyperstack.org/
+ Website master: https://hyperstack.org/

## License

Released under the MIT License.  See the [LICENSE][] file for further details.

[license]: LICENSE

## History

Hyperstack is an evolution of [Ruby-Hyperloop](https://github.com/ruby-hyperloop). We decided to rename the project to drop the Ruby suffix and also took the opportunity to simplify the repos and project overall.

+ Old website: http://ruby-hyperloop.org/
+ Old Github: https://github.com/ruby-hyperloop
+ Legacy branch: https://github.com/hyperstack-org/hyperstack/tree/hyperloop-legacy
+ Legacy install script: https://github.com/hyperstack-org/hyperstack/tree/hyperloop-legacy/install
 
