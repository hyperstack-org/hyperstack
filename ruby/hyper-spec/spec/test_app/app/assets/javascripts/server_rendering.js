//= require 'react-server'
//= require 'react_ujs'
//= require 'components'
if (typeof(OpalLoaded)=='undefined') {
  Opal.load('components');
} else {
  Opal.loaded(OpalLoaded || []);
  Opal.require("components");
}
