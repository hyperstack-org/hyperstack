# app/hyperstack/components/_base_classes
class HyperComponent
  include Hyperstack::Component
  include Hyperstack::State::Observable
  param_accessor_style :accessors
end
