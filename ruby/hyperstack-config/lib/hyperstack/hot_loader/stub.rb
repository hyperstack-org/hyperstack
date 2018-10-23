# insure that stubs for Hyperstack::HotLoader.record and window.Hyperstack.hotloader are defined
# importing 'hyperstack/hotloader' will define/redefine these

module Hyperstack
  unless defined? HotLoader
    class HotLoader
      def self.record(klass, instance_var, depth, *items); end
    end
  end
end

if `window.Hyperstack==undefined` || `window.Hyperstack.hotloader==undefined`
  `window.Hyperstack = { hotloader: function(port, ping) { }}`
end
