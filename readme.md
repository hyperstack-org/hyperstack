# Hyperstack

Hyperstack is a Ruby-based DSL and modern web toolkit for building spectacular, interactive web applications fast!

+ **One language** throughout the client and server - all Ruby code compiled by Opal into JavaScript automatically
+ Webpacker and Yarn modern web tooling with a **fast hot-reloader build environment**
+ Ruby DSL for wrapping **React** & **ReactRouter** as well as **any** JavaScript library or component
+ **Isomorphic Models with bi-directional data** so you can access your models as if they were on the client

All that means you can write simple front-end code like this:

```ruby
class GoodBooksToRead < Hyperstack::Component
  render(UL) do
    Book.good_books.each do |book|
      LI { "Read #{book.name}" }.on(:click) { display book } if book.available?
    end
  end
end
```

In the code above, if the `good_books` scope changed (even on the server) the UI would update automatically. Magical. That's React and Isomorphic Models with bi-directional data at work.

## Website and documentation

Please see the website for full documentation, or find the same content in the [/docs](/docs) folder in this repo if you prefer.

+ Website: [hyperstack.org](https://hyperstack.org)

Our website is an excellent Hyperstack example application. All the content is loaded dynamically from this repo, and it uses Semantic UI and a client-side JavaScript full-text search engine. Its a Rails application hosted on Heroku.

## Setup and installation

You can be up and running in **less than 5 minutes**. Just follow the simple setup guide for a new Rails application all perfectly configured and ready to go with Hyperstack.

+ Setup and Installation: [/install](/install)

## Community and support

Hyperstack is supported by a friendly, helpful community, both for users, and contributors. We welcome new people, reach out and say hello.

+ Reach us in Gitter: [Gitter chat](https://gitter.im/ruby-hyperloop/chat)

## Roadmap

Hyperstack is evolving, we are improving it all the time. Please see [ROADMAP][] file for more information.

[roadmap]: ROADMAP.md

## Contributing

If you would like to help, please read the [CONTRIBUTING][] file for suggestions.

[contributing]: CONTRIBUTING.md

## License

Released under the MIT License.  See the [LICENSE][] file for further details.

[license]: LICENSE
