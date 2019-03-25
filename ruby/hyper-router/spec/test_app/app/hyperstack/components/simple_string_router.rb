class SimpleStringRouter < HyperComponent
  include Hyperstack::Router
  render do
    'a simple string'
  end
end
