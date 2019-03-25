```ruby
class Picture < ApplicationRecord
  belongs_to :imageable, polymorphic: true
end

class Employee < ApplicationRecord
  has_many :pictures, as: :imageable
end

class Product < ApplicationRecord
  has_many :pictures, as: :imageable
end
```

product|employee.pictures -> works almost as normal has_many as far as Hyperstack client is concerned
imageable is the "alias" of product|employee.   Its as if there is a class Imageable that is the superclass
of Product and Employee.

so has_many :pictures means the usual thing (i.e. there is a belongs_to relationship on Picture) its just that
the belongs_to will be belonging to :imageable instead of :employee or :product.

okay fine

the other way:

the problem is that picture.imageable while loading is pointing to a dummy class (sure call it Imageable)
so if we say picture.imageable.foo.bar.blat what we get is a dummy value that responds to all methods, and returns itself:

picture.imageable -> imageable123 .foo -> imageable123 .bar -> ... etc.  but it is a dummy value that will cause a fetch of the actual imageable record (or nil).

.imageable should be able to leverage off of server_method.

server_method(:imageable, PolymorphicDummy.new(:imageable))

hmmmm....

really its like doing a picture.imageable.itself (?) (that may work Juuuust fine)

so picture.imageable returns this funky dummy value but does an across the wire request for picture.imageable (which should get imageable_id per a normal relationship) and also get picture.imageable_type.


start again....

what happens if we ignore (on the client) the polymorphic: and as:  keys?

belongs_to :imageable

means there is a class Imageable, okay so we make one, and add has_many :pictures to it.


and again....

```ruby
def imageable
  if imageable_type.loaded? && imageable_id.loaded?
    const_get(imageable_type).find(imageable_id)
  else
    DummyImageable.new(self)
  end
end
```

very close but will not work for cases like this:

```ruby
  pic = Picture.new
  employee.pictures << pic
  pic.imageable # FAIL... (until its been saved)
  ...
```

but still it may be as simple as overriding `<<` so that it sets type on imageable.  But we still to have a proper belongs to relationship.

```ruby
def imageable
  if we already have the attribute set
    return the attribute
  else
    set attribute to DummyPolyClass.new(self, 'imageable')
    # DummyPolyClass init will set up a fetch of the actual imageable value
  end
end

def imageable=(x)
  # will it just work ?
end
```

its all about the collection inverse.  The inverse class of the has_many is the class containing the polymorphic belongs to.  But the inverse of a polymorphic belongs to depends on the value. If the value is nil or a DummyPolyClass object then there is no inverse.

I think if inverse takes this into account then `<<` and `=` should just "work" (well almost) and probably everything else will to.

### NOTES on the DummyPolyClass...

it needs to respond to reflect_on_all_associations, but just return an empty array.  This way when we search for matching inverse attribute we won't find it.

### Status

added model to inverse, inverse_of, find_inverse

if the relationship is a collection then we will always know the inverse.

The only time we might no know the inverse is if its NOT a collection (i.e. belongs_to)

So only places that are applying inverse to an association that is NOT a collection do we have to pass the model in.

All inverse_of method calls have been checked and updated

that leaves inverse which is only used in SETTERS hurray!


### Latest thinking

going from `has_many / has_one as: ...` is easy  its essentially setting the association foreign_key using the name supplied to the as:

The problem is going from the polymorphic belongs_to side.  

We don't know the actual type we are loading which presents two problems.

First we just don't know the type.  So if I say `Picture.find(1).imageable.foo.bar` I really can't do anything with foo and bar.  This is solved by having a DummyPolymorph class, which responds to all missing methods with itself, and on creation sets up a vector to pull it the id, and type of the record being fetched.  This will cause a second fetch to actually get `foo.bar` because we don't know what they are yet.  (Its cool beacuse this is like Type inference actually, and I think we could eventually use a type inference system to get rid of the second fetch!!!)

Second we don't know the inverse of the relationship (since we don't know the type)

We can solve this by  aliasing the inverse relationship (the one with the `as: SOMENAME` option)   to be `has_many #{__hyperstack_polymorphic_inverse_of_#{SOMENAME}` and then defining method(s) against the relationship name.  This way regardless of what the polymorphic relationship points to we know the inverse is `__hyperstack_polymorphic_inverse_of_#{SOMENAME}`.  

If the inverse relationship is a has_many then we define
```ruby
def #{RELATIONSHIP_NAME}
  __hyperstack_polymorphic_inverse_of_#{SOMENAME}
end
```

If the inverse relationship is a has_one we have to work a bit harder:
```ruby
def #{RELATIONSHIP_NAME}
  __hyperstack_polymorphic_inverse_of_#{SOMENAME}[0]
end
def #{RELATIONSHIP_NAME}=(x)
  __hyperstack_polymorphic_inverse_of_#{SOMENAME}[0] = x # or perhaps we have to replace the array using the internal method in collection for that purpose.
end
```

The remaining problem is that the server side will have no such relationships defined so we need to add the `has_many __hyperstack_polymorphic_inverse_of_#{SOMENAME} as: SOMENAME` server side.
