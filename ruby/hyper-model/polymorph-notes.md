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

product/employee.pictures -> works almost as normal has_many as far as Hyperstack client is concerned
imageable is the "alias" of product/employee.   Its as if there is a class Imageable that is the superclass
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
