#config/initializers/synchromesh.rb
HyperMesh.configuration do |config|
  config.transport = :simple_poller
  # options
  # config.opts = {
  #   seconds_between_poll: 5, # default is 0.5 you may need to increase if testing with Selenium
  #   seconds_polled_data_will_be_retained: 1.hour  # clears channel data after this time, default is 5 minutes
  # }
end
