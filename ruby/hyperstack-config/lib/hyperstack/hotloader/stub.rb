# insure that stubs for Hyperstack::Hotloader.record and window.Hyperstack.hotloader are defined
# importing 'hyperstack/hotloader' will define/redefine these
# note that some internal hyperstack modules will use callbacks, which will call this, but it
# doesn't matter...

module Hyperstack
  unless defined? Hotloader
    class Hotloader
      def self.when_file_updates(&block); end
    end
  end
end
