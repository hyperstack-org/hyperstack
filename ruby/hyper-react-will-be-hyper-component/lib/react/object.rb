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
      React::Component::Tags.html_tag_class_for(const_name) || raise(e)
    end
  end
end
