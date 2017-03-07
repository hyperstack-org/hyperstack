module React
  module Component
    class Base
      def self.inherited(child)
        # note this is turned off during old style testing:  See the spec_helper
        unless child.to_s == "React::Component::HyperTestDummy"
          React::Component.deprecation_warning child, "The class name React::Component::Base has been deprecated.  Use Hyperloop::Component instead."
        end
        child.include(ComponentNoNotice)
      end
    end
  end
end
