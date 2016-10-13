module ReactiveRecord
  # Patches to DummyValue and find_record method
  class Base
    # make zero? of a DummyValue return false,
    # when reactive-record begins using the schema
    # keep in mind this behavior is for the dummy value of
    # collections
    class DummyValue < NilClass
      def zero?
        false
      end
    end
    # check to make sure that the object is not nil which can happen
    # now if you do something like Todo.scope1.scope2
    def self.find_record(model, id, vector, save)
      if !save
        found = vector[1..-1].inject(vector[0]) do |object, method|
          if object.nil? # happens if you try to do an all on empty scope followed by more scopes
            object
          elsif method.is_a? Array
            if method[0] == 'new'
              object.new
            else
              object.send(*method)
            end
          elsif method.is_a? String and method[0] == '*'
            object[method.gsub(/^\*/,'').to_i]
          else
            object.send(method)
          end
        end
        if id and (found.nil? or !(found.class <= model) or (found.id and found.id.to_s != id.to_s))
          raise "Inconsistent data sent to server - #{model.name}.find(#{id}) != [#{vector}]"
        end
        found
      elsif id
        model.find(id)
      else
        model.new
      end
    end
  end
end
