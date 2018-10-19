# rubocop:disable Style/FileName
# require 'reactrb/auto-import' to automatically
# import JS libraries and components when they are detected
if RUBY_ENGINE == 'opal'
  # modifies const and method_missing so that they will attempt
  # to auto import native libraries and components using Hyperstack::Component::NativeLibrary
  class Object
    class << self
      alias _reactrb_original_const_missing const_missing
      alias _reactrb_original_method_missing method_missing

      def const_missing(const_name)
        # Opal uses const_missing to initially define things,
        # so we always call the original, and respond to the exception
        _reactrb_original_const_missing(const_name)
      rescue StandardError => e
        Hyperstack::Internal::Component::NativeLibrary.import_const_from_native(Object, const_name, true) || raise(e)
      end

      def _reactrb_import_component_class(method)
        Hyperstack::Internal::Component::NativeLibrary.import_const_from_native(self, method, false)
      end

      def method_missing(method, *args, &block)
        component_class = _reactrb_import_component_class(method)
        _reactrb_original_method_missing(method, *args, &block) unless component_class
        Hyperstack::Component::Internal::RenderingContext.render(component_class, *args, &block)
      end
    end
  end

  # The public NativeLibrary can't be used directly to
  # import_const_from_native, because it is set to import from
  # `window.NativeLibrary`.  So we set up an internal class that won't
  #  have any prefix defined.
  module Hyperstack
    module Internal
      module Component
        class NativeLibrary < Hyperstack::Component::NativeLibrary
        end
      end
    end
  end
end
