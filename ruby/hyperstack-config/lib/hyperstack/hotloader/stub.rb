# insure that stubs for Hyperstack::Hotloader.record and window.Hyperstack.hotloader are defined
# importing 'hyperstack/hotloader' will define/redefine these

module Hyperstack
  unless defined? Hotloader
    class Hotloader
      def self.record(klass, instance_var, depth, *items); end
    end
  end
end

if `(typeof(window) !== 'undefined') && (window.Hyperstack==undefined || window.Hyperstack.hotloader==undefined)`
  `window.Hyperstack = { hotloader: function(port, ping) { }}`
end
