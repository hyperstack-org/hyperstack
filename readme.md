# Hyperstack
[![Build Status](https://travis-ci.com/hyperstack-org/hyperstack.svg?branch=edge)](https://travis-ci.com/hyperstack-org/hyperstack)
[![Gem Version](https://badge.fury.io/rb/rails-hyperstack.svg)](https://badge.fury.io/rb/rails-hyperstack)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Slack](https://img.shields.io/badge/slack-hyperstack.org/slack-yellow.svg?logo=slack)](https://join.slack.com/t/hyperstack-org/shared_invite/enQtNTg4NTI5NzQyNTYyLWQ4YTZlMGU0OGIxMDQzZGIxMjNlOGY5MjRhOTdlMWUzZWYyMTMzYWJkNTZmZDRhMDEzODA0NWRkMDM4MjdmNDE)


Hyperstack is a Ruby-based DSL and modern web toolkit for building spectacular, interactive web applications fast!

+ **One language** throughout the client and server. All Ruby code is compiled by [Opal](https://opalrb.com/) into JavaScript automatically.
+ Webpacker and Yarn tooling for a **modern, fast hot-reloader build environment with Ruby source maps**.
+ A well documented and stable Ruby DSL for wrapping **React** and **ReactRouter** as well as **any** JavaScript library or component. No need to learn JavaScript!
+ **Isomorphic Models with bi-directional data** so you can access your models as if they were on the client.

This means you can write simple front-end code like this:

```ruby
class GoodBooksToRead < HyperComponent
  render(UL) do
    Book.good_books.each do |book|
      LI { "Read #{book.name}" }
        .on(:click) { display book } if book.available?
    end
  end
end
```

In the code above, if the `good_books` scope changed (even on the server), the UI would update automatically. That's the magic of React and Isomorphic Models with bi-directional data at work!

## Website and documentation

Please see the website site for full documentation:

+ [hyperstack.org](https://hyperstack.org)

## Setup and installation

You can be up and running in **less than 5 minutes**. Just follow the simple setup guide for to add Hyperstack to a new or existing Rails application:

+ [Setup and Installation docs](https://docs.hyperstack.org/rails-installation/using-the-installer)

## Development Status

We now are issuing 1.0 release candidates weekly until all issues are either closed or moved to post 1.0 release status.  **Your opinion matters, plus take some time to up/down vote or comment on issues of interest.**


| Release<br/>Date | Version | Open<br/>Issues | Documentation<br/>Sections<br/>Draft Ready | Documentation<br/>Sections<br/>WIP |
|--------------|---------|-------------|-------|------|
| March 29, 2021 | 1.0.alpha1.6 | 167 | 35 | 10 |

> Open issues includes enhancements, documentation, and discussion issues as well as few bugs.
>
> The documentation WIP (work in progress) numbers are approx, as more sections may be added.

+ [Older Status Reports](https://github.com/hyperstack-org/hyperstack/blob/edge/current-status.md)


## Community and support

Hyperstack is supported by a friendly, helpful community, both for users, and contributors. We welcome new people, please reach out and say hello.

+ [Join](https://join.slack.com/t/hyperstack-org/shared_invite/enQtNTg4NTI5NzQyNTYyLWQ4YTZlMGU0OGIxMDQzZGIxMjNlOGY5MjRhOTdlMWUzZWYyMTMzYWJkNTZmZDRhMDEzODA0NWRkMDM4MjdmNDE) our Slack group
+ After you have joined there is a shortcut at https://hyperstack.org/slack

### StackOverflow Questions

Please ask technical questions on StackOverflow as the answers help people in the future. We use the `hyperstack` tag, but also add `ruby-on-rails`, `ruby` and `react-js` tags to get this project exposed to a broader community.

+ Please ask questions here: https://hyperstack.org/question
+ All the `hyperstack` tagged questions are here: https://hyperstack.org/questions

## Contributing

If you would like to help, please read the [CONTRIBUTING][] file for suggestions.

[contributing]: CONTRIBUTING.md

## License

Released under the MIT License.  See the [LICENSE][] file for further details.

[license]: LICENSE
