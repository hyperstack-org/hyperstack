# Lazy load HTML tag constants in the form DIV or A
# This is needed to allow for a HAML expression like this DIV.my_class
class Object
  class << self
    alias _reactrb_tag_original_const_missing const_missing

    def const_missing(const_name)
      # Opal uses const_missing to initially define things,
      # so we always call the original, and respond to the exception
      _reactrb_tag_original_const_missing(const_name)
    rescue StandardError => e
      Hyperstack::Internal::Component::Tags.html_tag_class_for(const_name) || raise(e)
    end
  end
  # to_key method returns a suitable unique id that can be used as
  # a react `key`.  Other classes may override to_key as needed
  # for example hyper_mesh returns the object id of the internal
  # backing record.
  #
  # to_key is automatically called on objects passed as keys for
  # example Foo(key: my_object) results in Foo(key: my_object.to_key)
  def to_key
    object_id
  end
end
