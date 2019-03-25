require 'hyperstack/internal/component/haml'
# to allow for easier testing we include the internal mixins
# from hyperstack/internal/component/haml
# see spec/deprecated_features/haml_spec
module Hyperstack
  module Internal
    module Component
      module Tags
        include HAMLTagInstanceMethods
      end
    end
  end
  module Component
    class Element
      include HAMLElementInstanceMethods
    end
  end
end
