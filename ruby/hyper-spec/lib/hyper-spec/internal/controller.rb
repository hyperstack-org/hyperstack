module HyperSpec
  module Internal
    module Controller
      class << self
        attr_accessor :current_example
        attr_accessor :description_displayed

        def test_id
          @_hyperspec_private_test_id ||= 0
          @_hyperspec_private_test_id += 1
        end

        include ActionView::Helpers::JavaScriptHelper

        def current_example_description!
          title = "#{title}...continued." if description_displayed
          self.description_displayed = true
          "#{escape_javascript(current_example.description)}#{title}"
        end

        def file_cache
          @file_cache ||= FileCache.new('cache', '/tmp/hyper-spec-caches', 30, 3)
        end

        def cache_read(key)
          file_cache.get(key)
        end

        def cache_write(key, value)
          file_cache.set(key, value)
        end

        def cache_delete(key)
          file_cache.delete(key)
        rescue StandardError
          nil
        end
      end

      # By default we assume we are operating in a Rails environment and will
      # hook in using a rails controller.  To override this define the
      # HyperSpecController class in your spec helper.  See the rack.rb file
      # for an example of how to do this.

      def hyper_spec_test_controller
        return ::HyperSpecTestController if defined?(::HyperSpecTestController)

        base = if defined? ApplicationController
                 Class.new ApplicationController
               elsif defined? ::ActionController::Base
                 Class.new ::ActionController::Base
               else
                 raise "Unless using Rails you must define the HyperSpecTestController\n"\
                       'For rack apps try requiring hyper-spec/rack.'
               end
        Object.const_set('HyperSpecTestController', base)
      end

      # First insure we have a controller, then make sure it responds to the test method
      # if not, then add the rails specific controller methods.  The RailsControllerHelpers
      # module will automatically add a top level route back to the controller.

      def route_root_for(controller)
        controller ||= hyper_spec_test_controller
        controller.include RailsControllerHelpers unless controller.method_defined?(:test)
        controller.route_root
      end
    end
  end
end
