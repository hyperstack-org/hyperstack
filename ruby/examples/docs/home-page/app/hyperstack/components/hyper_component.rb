class HyperComponent
  include Hyperstack::Component
  include Hyperstack::State::Observable
  param_accessor_style :accessor
end
