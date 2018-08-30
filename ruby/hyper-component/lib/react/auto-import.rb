# rubocop:disable Style/FileName
# require 'react/auto-import' to automatically
# import JS libraries and components when they are detected
if RUBY_ENGINE == 'opal'
  # modifies const and method_missing so that they will attempt
  # to auto import native libraries and components using React::NativeLibrary
  class Object
    class << self
      alias _react_original_const_missing const_missing
      alias _react_original_method_missing method_missing

      def const_missing(const_name)
        # Opal uses const_missing to initially define things,
        # so we always call the original, and respond to the exception
        _react_original_const_missing(const_name)
      rescue StandardError => e
        React::NativeLibrary.import_const_from_native(Object, const_name, true) || raise(e)
      end

      def method_missing(method, *args, &block)
        # ToDo: call import_const_from_natve only, if methods starts with capital letter
        component_class = React::NativeLibrary.import_const_from_native(self, method, false)
        return _react_original_method_missing(method, *args, &block) unless component_class
        React::RenderingContext.render(component_class, *args, &block)
      end
    end
  end
end
