typically we see this:

`State.get_state(obj_or_class, key)` and  `State.set_state(obj_or_class, key, val)`

we would like to see this:

`obj.key.state`  and `obj.key.state = val`

plus `obj.key.mutate` which is short for
`obj.key.state.tap { |val| val... some mutation; val.key.state = val}`

problems:

1. creates a state object for each key - the only purpose this serves is preventing accidental application of `key = ...` instead of `self.key = `

2. difficult to use application defined keys like Model attributes - have to call the `state` macro for each key before use.

3. many of the objects have only a single state, so `obj.my_only_state.state` is redundant.

what do we want to say?

`obj.states[key]`  or  `obj.states[key] = val` or `obj.mutates[key]`

and in the case of an object with a single state:

`obj.state # reader` and  
`obj.state = val # setter - careful of self.state = problem` and  
`obj.mutate`

for the first case we could say:

`state :states, hash: :mutates`

for the second case it would be implemented like this:

```ruby
state :state_obj
def state
  state_obj.state
end

def state=(val)
  state_obj.state = val
end

def mutate
  state_obj.mutate
end
```

and perhaps this would be done by using a subclass instead of include?

```ruby
class MyStatefulClass < Hyperstack::State::Base
  #... how to do it the class level?
end
```


MORE THOUGHTS ON SINGLE STATE OBJECTS

typically we have some instance variable that is the
reactive state.  We may want to read and change that variable
internally without reaction

so one approach would be to just provide two methods: `observed!` and `mutated!`
```ruby
def observed!
  State.get_state(self, self)
end

def mutated!
  State.set_state(self, self, self)
end
```

### So here is the deal

If you want to make some arbitrary piece of data *stateful* then you have to deal with arrays, or at least some kind of data that can be addressed.

hmmm not exactly right... the thing is we want to build state objects out of state variables and variables can be arrays (or other addressable primitive structures).

so lets say we want to build a reactive hash class, but we want each key to be its own reactive variable.

We could create the reactive hash class with an internal class called ReactiveHashValue, where each reactive_hash_value knows its key, its value, and inherits from Observable.  

http://opalrb.com/try/?code:class%20Foo%0A%20%20def%20initialize(x)%0A%20%20%20%20%40x%20%3D%20x%0A%20%20end%0A%20%20def%20meth%0A%20%20%20%20%40x%0A%20%20end%0Aend%0A%0Aputs%20Foo.new(12).meth%0A%0Aclass%20Bar%0A%20%20def%20self.new(x)%0A%20%20%20%20return%20%60%7B%24meth%3A%20function()%20%7B%20return%20(x)%20%7D%20%7D%60%0A%20%20end%0Aend%0A%0Aputs%20Bar.new(12).meth%0A%0Adef%20speedy(x)%0A%20%20return%20%60%7B%24meth%3A%20function()%20%7Breturn%20(x)%20%7D%20%7D%60%0Aend%0A%0Aputs%20speedy(12).meth%0A%0A%0Adef%20timeit(x)%20%0A%20%20start_time%20%3D%20Time.now.to_f%0A%20%20x.times.each%20%7B%20yield%20%7D%0A%20%20(Time.now.to_f%20-%20start_time)%20%2F%20x%0Aend%0A%0Aputs%20timeit(1_000_000)%20%7B%20Foo.new(12).meth%20%7D%0Aputs%20timeit(1_000_000)%20%7B%20speedy(12).meth%20%7D%0Aputs%20timeit(1_000_000)%20%7B%20Bar.new(12).meth%20%7D


```ruby
module Observable
  # adds state methods to a class
  # adds the mutated!  and observed! methods to instance and class
  # which can be used to notify of changes to the instance or classes state
end

class ObservableState
  # contains a single state value methods such as state, state= and mutate
end

# Observable uses ObservableState for each state variable, and also for the single class and
# instance state variables representing the state of the class as a whole.

```
