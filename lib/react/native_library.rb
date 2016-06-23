module React
  # NativeLibrary handles importing JS libraries
  # Importing native components is handled by the
  # React::Base.
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
            create_wrapper(native_name, ruby_name)
          else
            raise "class #{name} < React::NativeLibrary could not import #{js_name}. "\
            "Native value #{scope_native_name(js_name)} is undefined."
          end
        end
      end

      def import_const_from_native(klass, const_name)
        puts "#{klass} is importing_const_from_native: #{const_name}"
        if klass.defined? const_name
          klass.const_get const_name
        else
          native_name = lookup_native_name(const_name) ||
                        lookup_native_name(const_name[0].downcase + const_name[1..-1])
          wrapper = create_wrapper(klass, native_name, const_name) if native_name
          puts "created #{wrapper} for #{const_name}"
          wrapper
        end
      end

      def find_and_render_component(container_class, component_name, args, block, &_failure)
        puts "#{self} is registering #{method_name}"
        component_class = import_const_from_native(container_class, method_name)
        if component_class < React::Component::Base
          React::RenderingContext.build_or_render(nil, component_class, *args, &block)
        else
          yield method_name
        end
      end

      def const_missing(const_name)
        import_const_from_native(self, const_name) || super
      end

      def method_missing(method_name, *args, &block)
        find_and_render_component(self, method_name, args, block) do
          raise "could not import a react component named: #{scope_native_name method_name}"
        end
      end

      private

      def lookup_native_name(js_name)
        native_name = scope_native_name(js_name)
        `eval(#{native_name}) !== undefined && native_name`
      rescue
        nil
      end

      def scope_native_name(js_name)
        "#{@native_prefix}#{js_name}"
      end

      def create_wrapper(klass, native_name, ruby_name)
        if React::API.import_native_component native_name
          puts "create wrapper(#{klass.inspect}, #{native_name}, #{ruby_name})"
          new_klass = Class.new
          klass.const_set ruby_name, new_klass
          new_class.class_eval do
            include React::Component::Base
            imports native_name
          end
          puts "successfully created #{klass.inspect}.#{ruby_name} wrapper class for #{native_name}"
        else
          puts "creating wrapper class #{klass}::#{ruby_name} for #{native_name}"
          klass.const_set ruby_name, Class.new(React::NativeLibrary).imports(native_name)
        end
      end
    end
  end
end
