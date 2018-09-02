module Hyperloop
  # Tricky business here. Hyperloop::Store will define boot
  # if it is not already defined.  It creates a minimal compatible
  # API that includes the run and on_dispatch methods.  This way
  # you can use the Boot interface without loading operations.

  # Here we define Boot, but in case it has already been defined
  # we make sure to run the inherited method, and define the
  # on_dispatch and run methods.   Finally we copy any receivers
  # that may have been defined on the existing Boot to the new class.
  class Application
    Operation.inherited(Boot) if defined? Boot
    class Boot < Operation
      def self.on_dispatch(&block)
        _Railway.add_receiver(&block)
      end
      def self.run(*args)
        ClientDrivers.initialize_client_drivers_on_boot
        _run(*args)
      end
    end
    Boot.receivers.each { |r| Boot.on_dispatch(&r) } if Boot.respond_to? :receivers
  end
end
