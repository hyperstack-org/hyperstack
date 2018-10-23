//= require hyperstack-loader-system-code
//= require hyperstack-loader-application
//= require hyperstack-hotloader-config
Opal.load('hyperstack-loader-system-code')
Opal.load('hyperstack-loader-application')
Hyperstack.hotloader(Hyperstack.hotloader.port, Hyperstack.hotloader.ping)
