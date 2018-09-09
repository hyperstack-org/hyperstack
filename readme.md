# Hyperstack

## Description

Hyperstack is a Ruby-based DSL and modern web tooling for building spectacular, interactive web applications. 

+ **One language** throughout the client and server - all Ruby code compiled by Opal into JavaScript automatically
+ Webpacker and Yarn **modern web tooling** with a fast hot-loader build environment
+ Ruby DSL for wrapping **React** & **ReactRouter** as well as **any** JavaScript library or component
+ **Isomorphic Models with bi-directional data** - access your models as if they were on the client 

All that means you can write simple front-end code like this:

```ruby
class BookList < Hyperstack::Component
  render(UL) do
    Book.for_sale.each do |book|
      LI { "Buy #{book.name}" }.on(:click) { purchase book } if book.available?
    end
  end
end
```
You can be up and running in **less than 5 minutes**. Just follow the simple setup guide for a new Rails application all perfectly configured and ready to go with Hyperstack.

## Website and documentation

Please see the website for full documentation, or find the same content in the `docs` folder in this repo if you prefer.

+ [hyperstack.org](https://hyperstack.org)

Our website is an excellent Hyperstack example application. All the content is loaded dynamically from this repo, and it uses Semantic UI and a client-side JavaScript full-text search engine. Its a Rails application hosted on Heroku. 

## Setup and installation

You can up and going with a HelloWorld application in less than 5 minutes from now. 

+ [Setup and Installation](/install)

## Contributing

If you would like to help, please read the [CONTRIBUTING][] file for suggestions.

[contributing]: CONTRIBUTING.md

## Roadmap

Hyperstack is evolving. Please see [ROADMAP][] file for more information.

[roadmap]: ROADMAP.md

## License

Released under the MIT License.  See the [LICENSE][] file for further details.

[license]: LICENSE
