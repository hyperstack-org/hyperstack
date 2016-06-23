# rubocop:disable Style/FileName
# require 'reactrb/auto-import' to automatically
# import JS libraries and components when they are detected
class Object
  class << self
    alias _reactrb_original_const_missing const_missing

    def const_missing(const_name)
      # Opal uses const_missing to initially define things,
      # so we always call the original, and respond to the exception
      _reactrb_original_const_missing(const_name)
    rescue StandardError => e
      puts "Object const_missing: #{const_name}"
      React::NativeLibrary.import_const_from_native(Object, const_name) || raise(e)
    end

    def xmethod_missing(method_name, *args, &block)
      puts "Object method_missing: #{method_name}"
      React::NativeLibrary.register_method(Object, method_name, args, block) do
        _reactrb_original_const_missing(method_name, *args, &block)
      end
    end
  end
end
