//= require hyperstack-loader-system-code
//= require hyperstack-loader-application
//= require hyperstack-hotloader-config
Opal.loaded(OpalLoaded || [])
Opal.require('hyperstack-loader-system-code')
Opal.loaded(OpalLoaded || [])
Opal.require('hyperstack-loader-application')
Hyperstack.hotloader(Hyperstack.hotloader.port, Hyperstack.hotloader.ping)
