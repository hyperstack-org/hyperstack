# Each Hyperstack application should define a base
# HyperComponent class.  This where application wide
# specific hooks can be added to customize behavior across
# the application.

# In this case we attach hypertrace instrumentation to all
# of our components so we get debug tracing of what is going on.

class HyperComponent
  include Hyperstack::Component
  include Hyperstack::State::Observable
end.hypertrace instrument: :all
