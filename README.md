# hyper-transport

Various transport options for ruby-hyperloop and hyper-stack.
Supports:
- Pusher
- ActionCable
- WebSocket
- HTTP Ajax

## Installation
hyper-transport is automatically installed if you use hyper-resource.
Otherwise add to your Gemfile:
```ruby
gem 'hyper-transport'
```
and bundle install/update

## Usage
### Pusher
in your client code add:
```ruby
require 'hyper-transport-pusher'
```
Currently supports Pusher Channels.
```ruby

```
### ActionCable
in your client code add:
```ruby
require 'hyper-transport-action-cable'
```
### WebSocket
in your client code add:
```ruby
require 'hyper-transport-web-socket'
```
### HTTP Ajax
in your client code add:
```ruby
require 'hyper-transport-http'
```
