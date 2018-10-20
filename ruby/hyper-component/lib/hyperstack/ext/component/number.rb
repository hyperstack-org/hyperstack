# to_key method returns a suitable unique id that can be used as
# a react `key`.  Other classes may override to_key as needed
# for example hyper_mesh returns the object id of the internal
# backing record.
#
# to_key is automatically called on objects passed as keys for
# example Foo(key: my_object) results in Foo(key: my_object.to_key)

# for Number to_key can just be the number itself
class Number
  def to_key
    self
  end
end
