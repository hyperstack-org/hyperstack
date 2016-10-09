module ReactiveRecord
  # Add the when_not_saving method to reactive-record.
  # This will wait until reactive-record is not saving a model.
  # Currently there is no easy way to do this without polling.
  class Base

    def self.find_record(model, id, vector, save)
      if !save
        found = vector[1..-1].inject(vector[0]) do |object, method|
          if object.nil? # happens if you try to do an all on empty scope followed by more scopes
            object
          elsif method.is_a? Array
            if method[0] == "new"
              object.new
            else
              object.send(*method)
            end
          elsif method.is_a? String and method[0] == "*"
            object[method.gsub(/^\*/,"").to_i]
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
