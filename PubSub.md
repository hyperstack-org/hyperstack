## PubSub with HyperResource

PubSub is handled in the controller. In your controller:
```
include Hyperloop::Resource::PubSub
```

Then you can use the PubSub methods of Hyperloop::Resource::PubSub.

For example, a record has been requested, subscribe to it in the show action of the controller:
```
  subscribe_record(my_record)
```

When somebody updates the record, in the update action for example:
```
  publish_record(record)
```

All subscribers will receive a message indicating, that the record has been updated.
