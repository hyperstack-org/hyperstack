Hyper-Model provides two API levels

The high level API and the promise API

## High level API

The high level api allows for a simple use of records and is in general recommended for read accesses. For write accesses, saving of data, the promise API is recommended, unless weather the data was saved or not is not of importance.

#### Schema of accessing data in the high level API:

```
my_record = MyModel.find('1')
my_record.a_property
```

1. component is rendered
2. during render a fetch is triggered
2.1 component is registered as observer
2.2 component gets dummy data to render
3. render completes, data is fetched in the background
4. when the data arrived
4.1 the component as observer is notified
4.2 a state change happens and the component is rendered again with the real data

#### Schema of saving data in the high level API

```
my_record.a_property = 2
my_record.save
```

Saving of data in the high level API is optimistic:

1. triggering a save of data
2. the method called returns immediately
3. a successful save is assumed

## Promise API

All methods of the promise API are prefixed by 'promise_', so instead of my_redord.save in the high level API, in the promise API one would use my_record.promise_save.
All methods in the promise API return a promise.
In general the pattern is:

```
my_record.a_property = 2

my_record.promise_save.then do |record|
  # save was successful
  # do something here
end.fail do |response|
  # save failed
  # response is the http response object
end
```

for example, finding a record:

```
MyModel.promise_find('1').then do |record]
  my_record.a_property
end
```