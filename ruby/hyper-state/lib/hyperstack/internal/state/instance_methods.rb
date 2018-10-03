module Hyperstack
  module Internal
    class State
      module InstanceMethods
        def initialize(object, name, initializer)
          @object = object
          @name = name
          @observer = Observer.new(self)
          return unless initializer
          self.state =
            if initializer.lambda?
              object.instance_exec(&initializer)
            else
              object.instance_eval(&initializer)
            end
        end

        def to_s
          "<#{@object}.#{@name} : #{self.class.states[@object][@name]}>"
        end

        def inspect
          "<#{@object.to_s}.#{@name} : #{self.class.states[@object][@name].inspect}>"
        end

        def state
          self.class.get_state(@object, @name)
        end

        def toggle!
          self.class.set_state(@object, @name, !self.class.get_state(@object, @name))
        end

        def set?
          !!self.class.get_state(@object, @name)
        end

        def clear?
          !self.class.get_state(@object, @name)
        end

        def nil?
          self.class.get_state(@object, @name).nil?
        end

        def state=(new_value)
          self.class.set_state(@object, @name, new_value)
          new_value
        end

        def __non_reactive_read__
          self.class.states[@object][@name]
        end

        def mutate
          @observer
        end

        def mutated(&block)
          state
          yield
          self
        end
      end
    end
  end
end
