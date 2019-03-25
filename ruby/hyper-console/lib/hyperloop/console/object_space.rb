class Object
  def self.instance
    ObjectSpace.objects(self).tap do |arr|
      arr.define_singleton_method(:console) { |*args| method_missing(:console, *args) }
      klass = self
      arr.define_singleton_method(:method_missing) do |method, *args, &block|
        if length > 1 && self[0].respond_to?(method)
          raise "Ambiguous #{klass}.instance.#{method} application.\n"\
          "There are #{length} instances of #{klass}.\n"\
          "You can either apply #{method} to a specific instance using #{klass}.instance[x].#{method};\n"\
          "or use an enumerator method like each or collect."
        elsif length == 0
          raise "There are no #{klass} instances."
        else
          self[0].send(method, *args, &block)
        end
      end
    end
  end
end

module ObjectSpace
  def self.objects(klass)
    objs = []
    matching_objs = []
    %x{
      var walk_the_object = function(js_obj) {
        var keys = Object.keys(js_obj) //get all own property names of the object

        keys.forEach( function ( key ) {
          if ( key != '$$proto' ) {
            var value = js_obj[ key ]; // get property value

            // if the property value is an object...
            if ( value && typeof value === 'object'  ) {

                // if we don't have this reference, and its an object of the class we want
                if ( #{objs}.indexOf( value ) < 0 ) {
                    #{objs}.push( value ); // store the reference
                    if ( Object.keys(value).indexOf('$$id') >= 0 && value.$$class == #{klass} ) {
                      #{matching_objs}.push ( value )
                    }
                    walk_the_object(value) // traverse all its own properties
                }
            }
          }
        })
      }
      walk_the_object(window)
    }
    matching_objs
  end
end
