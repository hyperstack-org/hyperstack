# Welcome

Hyperstack is a Ruby-based DSL and modern web toolkit for building spectacular, interactive web applications fast!

* **One language** throughout the client and server. All Ruby code is compiled by [Opal](https://opalrb.com/) into JavaScript automatically.
* Webpacker and Yarn tooling for a **modern, fast hot-reloader build environment with Ruby source maps**.
* A well documented and stable Ruby DSL for wrapping **React** and **ReactRouter** as well as **any** JavaScript library or component. No need to learn JavaScript!
* **Isomorphic Models with bi-directional data** so you can access your models as if they were on the client.

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

In the code above, if the `good_books` scope changed \(even on the server\), the UI would update automatically. That's the magic of React and Isomorphic Models with bi-directional data at work!

## Website and Documentation

<img align="left" width="100" height="100" style="margin-right: 20px" src="https://github.com/hyperstack-org/hyperstack/blob/edge/docs/wip.png?raw=true">

While we have over 1000 specs passing, in 3 different configurations, and several large apps using Hyperstack, documentation is a lagging.  If you see this icon it means we are working hard to
get the docs up to the same state as the code.

Chapters without the work-in-progress flag, are still draft, and any issues are greatly appreciated, or better yet follow the `Edit on Github` link make your propsed corrections, and submit a pull request.

## Setup and installation

You can be up and running in **less than 5 minutes**. Just follow the simple setup guide for a new Rails application all correctly configured and ready to go with Hyperstack.

* Setup and Installation: https://docs.hyperstack.org/rails-installation

Beyond the installation we strongly suggest new developers work trough the [todo tutorial](https://docs.hyperstack.org/tutorial). As it gives a minimal understanding of the Hyperstack framework.

## Community and support

Hyperstack is supported by a friendly, helpful community, both for users, and contributors. We welcome new people, please reach out and say hello.

* Reach us at: [Slack chat](https://join.slack.com/t/hyperstack-org/shared_invite/enQtNTg4NTI5NzQyNTYyLWQ4YTZlMGU0OGIxMDQzZGIxMjNlOGY5MjRhOTdlMWUzZWYyMTMzYWJkNTZmZDRhMDEzODA0NWRkMDM4MjdmNDE)

## Roadmap

We are currently driving towards our 1.0 release.  Currently we are at 1.0.alpha1.5 release candidate.  There is a list of 163 open issues including some bugs, many requested enhancements.  The plan is to triage the issues, and do a weekly release until the issues are closed as deemed not needed for a 1.0 release.  

Please consider contributing by grabbing a "good first issue", or just adding your thoughts, thumbs up, or down on any issues that interest you.

## Contributing

In general, if you would like to help in any way, please read the [CONTRIBUTING](https://github.com/hyperstack-org/hyperstack/blob/edge/CONTRIBUTING.md) file for suggestions.  
System setup for the development of Hyperstack itself is documented in this file.

More specifically, we have a [Feature Matrix](https://github.com/hyperstack-org/hyperstack/blob/edge/docs/feature_matrix.md) that needs to be filled with missing features. The idea is that you can check here what the implementation status is of a Ruby \(on Rails\) feature. And if you have the time and skill you're more then encouraged to implement or fix one or two. But if you're not in a position to contribute code, just expanding and maintaining this table would be excellent.

## Links

* Rubygems: [https://rubygems.org/profiles/hyperstack](https://rubygems.org/profiles/hyperstack)
* Travis: [https://travis-ci.org/hyperstack-org](https://travis-ci.org/hyperstack-org)
* Website edge: [https://edge.hyperstack.org/](https://edge.hyperstack.org/)
* Website master: [https://hyperstack.org/](https://hyperstack.org/)

## License

Hyperstack is developed and released under the MIT License. See the [LICENSE](https://github.com/hyperstack-org/hyperstack/blob/edge/LICENSE) file for further details.
