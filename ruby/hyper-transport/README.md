# hyper-transport

Various transport options for hyperstack.
Supports:
- Pusher
- ActionCable
- WebSockets (NI)
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
### WebSocket (NI)
in your client code add:
```ruby
require 'hyper-transport-web-socket'
```
### HTTP Ajax
in your client code add:
```ruby
require 'hyper-transport-http'
```
