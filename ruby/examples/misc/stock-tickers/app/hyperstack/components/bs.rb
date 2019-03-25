class BS < Hyperstack::Component::NativeLibrary
  # subclasses of Hyperstack::Component::NativeLibrary
  # are wrappers around JS component libraries.
  # once imported BS acts like an ordinary ruby module
  
  imports 'ReactBootstrap'
end
