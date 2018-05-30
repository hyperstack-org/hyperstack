# hyper-resource

[Github Repo](https://github.com/janbiedermann/hyper-resource "Github Repo")
HyperResource is an affective way of moving data between your server and clients when using Hyperloop and Rails.

[![Reactivity Demo](http://img.youtube.com/vi/fPSpESBbeMQ/0.jpg)](http://www.youtube.com/watch?v=fPSpESBbeMQ "Reactivity Demo")

## Motivation

+ To co-exist with a resource based REST API
+ To have ActiveRecord type Models shared by both the client and server code
+ To be ORM/database agnostic (tested with ActiveRecord on Postgres and Neo4j.rb on Neo4j)
+ To fit the 'Rails way' as far as possible (under the covers, HyperResource is a traditional REST API)
+ To keep all Policy checking and authorisation logic in the Rails Controllers
+ To allow a stages implementation

## Staged implementation

HyperResource is designed to be implemented in stages and each stage delivers value in its own right, so the developer only needs to go as far as they like.

A record can be of any ORM but the ORM must implement:
```ruby
record_class.find(id) # to get a record
record.id # a identifier
record.updated_at # a time stamp
record.destroyed? # to identify if its scheduled for destruction

# when using relations controller
record.touch # to update updated_at, identicating that something about that record changed
             # for example it has been added to a relation
```

### Stage 1 - Wrap a REST API with Ruby classes to represent Models

The simplest implementation of HyperResource is a client side only wrapper of an existing REST API which treats each REST Resource as a Ruby class.

```ruby
# in your client-cide code
class Customer
  include ApplicationHyperRecord
end

# then work with the Customer class as if it were an ActiveRecord
customer = Customer.new(name: 'John Smith')
customer.save # ---> POST api/customer.json ... {name: 'John Smith' }
puts customer.id # 123

# to find a record
customer = Customer.find(123) # ---> GET api/customer/123.json
puts customer.name # `John Smith`
```

### Stage 2 - Adapt your Models so the client and server code share the same Models

HyperResource supports ActiveRecord associations and scopes so you can DRY up your code and the client an server can share the same Models.

```ruby
module ApplicationHyperRecord
  def self.included(base)
    if RUBY_ENGINE == 'opal'
      base.include(HyperRecord)
    else
      base.extend(HyperRecord::ServerClassMethods)
    end
  end
end

class Customer
  include ApplicationHyperRecord
  has_many :addresses

  unless RUBY_ENGINE == 'opal'
    # methods which should only exist on the server
  end
end

customer = Customer.find(123) # ---> GET api/customer/123.json
customer.addresses.each do |address|
  puts address.post_code
end
```

### Stage 3 - Implement a Redis based pub-sub mechanism so the client code is notified when the server data changes

```ruby
class ApplicationController
  include Hyperloop::Resource::PubSub

  def my_action
    # available methods for pubsub
    publish_collection(base_record, collection_name, record = nil)
    publish_record(record)
    publish_scope(record_class, scope_name)

    subscribe_collection(collection, base_record = nil, collection_name = nil)
    subscribe_record(record)
    subscribe_scope(collection, record_class = nil, scope_name = nil)

    pub_sub_collection(collection, base_record, collection_name, causing_record = nil)
    pub_sub_record(record)
    pub_sub_scope(collection, record_class, scope_name)
  end
end
```

EXAMPLE

## Implementation

How to install....
