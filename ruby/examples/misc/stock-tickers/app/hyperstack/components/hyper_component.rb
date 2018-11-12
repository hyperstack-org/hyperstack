def Hyperstack.naming_convention
  :prefix_params
end

class HyperComponent
  include Hyperstack::Component
  include Hyperstack::State::Observable
end.hypertrace instrument: :all
