## Upgrading to hyper-react from Reactrb

Follow these steps to upgrade:

1. Replace `reactrb` with `hyper-react` both in **Gemfile** and any `require`s in your code.
2. To include the React.js source, the suggested way is to add `require 'react/react-source'` before `require 'hyper-react'`. This will use the copy of React.js source from `react-rails` gem.

## Upgrading to Reactrb

The original gem `react.rb` was superceeded by `reactive-ruby`, which has had over 15,000 downloads.  This name has now been superceeded by `reactrb` (see #144 for detailed discussion on why.)

Going forward the name `reactrb` will be used consistently as the organization name, the gem name, the domain name, the twitter handle, etc.

The first initial version of `reactrb` is 0.8.x.

It is very unlikely that there will be any more releases of the `reactive-ruby` gem, so users should upgrade to `reactrb`.

There are no syntactic or semantic breaking changes between `reactrb` v 0.8.x and
previous versions, however the `reactrb` gem does *not* include the react-js source as previous versions did.  This allows you to pick the react js source compatible with other gems and react js components you may be using.

Follow these steps to upgrade:

1. Replace `reactive-ruby` with `reactrb` both in **Gemfile** and any `require`s in your code.
2. To include the React.js source, the suggested way is to add `require 'react/react-source'` before `require 'reactrb'`. This will use the copy of React.js source from `react-rails` gem.
