module React
  # NativeLibrary handles importing JS libraries. Importing native components is handled
  # by the React::Base.  It also provides several methods used by auto-import.rb

  # A NativeLibrary is simply a wrapper that holds the name of the native js library.
  # It responds to const_missing and method_missing by looking up objects within the js library.
  # If the object is a react component it is wrapped by a reactrb component class, otherwise
  # a nested NativeLibrary is returned.

  # Two macros are provided: imports (for naming the native library) and renames which allows
  # the members of a library to be given different names within the ruby name space.

  # Public methods used by auto-import.rb are import_const_from_native and find_and_render_component
  class NativeLibrary
    class << self
      def imports(native_name)
        @native_prefix = "#{native_name}."
        self
      end

      def rename(rename_list)
        # rename_list is a hash in the form: native_name => ruby_name, native_name => ruby_name
        rename_list.each do |js_name, ruby_name|
          native_name = lookup_native_name(js_name)
          if lookup_native_name(js_name)
            create_component_wrapper(self, native_name, ruby_name) ||
              create_library_wrapper(self, native_name, ruby_name)
          else
            raise "class #{name} < React::NativeLibrary could not import #{js_name}. "\
            "Native value #{scope_native_name(js_name)} is undefined."
          end
        end
      end

      def import_const_from_native(klass, const_name, create_library)
        native_name = lookup_native_name(const_name) ||
                      lookup_native_name(const_name[0].downcase + const_name[1..-1])
        native_name && (
          create_component_wrapper(klass, native_name, const_name) || (
            create_library &&
              create_library_wrapper(klass, native_name, const_name)))
      end

      def const_missing(const_name)
        import_const_from_native(self, const_name, true) || super
      end

      def method_missing(method, *args, &block)
        component_class = const_get(method) if const_defined?(method, false)
        component_class ||= import_const_from_native(self, method, false)
        raise 'could not import a react component named: '\
              "#{scope_native_name method}" unless component_class
        React::RenderingContext.render(component_class, *args, &block)
      end

      private

      def lookup_native_name(js_name)
        native_name = scope_native_name(js_name)
        `eval(#{native_name}) !== undefined && native_name`
      # rubocop:disable Lint/RescueException  # that is what eval raises in Opal >= 0.10.
      rescue Exception
        nil
        # rubocop:enable Lint/RescueException
      end

      def scope_native_name(js_name)
        "#{@native_prefix}#{js_name}"
      end

      def create_component_wrapper(klass, native_name, ruby_name)
        if React::API.native_react_component?(native_name)
          new_klass = klass.const_set ruby_name, Class.new
          new_klass.class_eval do
            include Hyperloop::Component::Mixin
            imports native_name
          end
          new_klass
        end
      end

      def create_library_wrapper(klass, native_name, ruby_name)
        klass.const_set ruby_name, Class.new(React::NativeLibrary).imports(native_name)
      end
    end
  end
end
