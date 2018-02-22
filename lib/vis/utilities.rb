module Vis
  module Utilities
    def self.included(klass)
      klass.extend Vis::Utilities::Native
    end
    
    module Native
      def native_methods_with_options(js_names)
        js_names.each do |js_name|
          native_method_with_options(js_name)
        end
      end

      def native_method_with_options(js_name)
        define_method(js_name.underscore) do |options|
          @native.JS.call(js_name, options_to_native(options))
        end
      end
    end

    def hash_array_to_native(array)
      array.map(&:to_n)
    end

    def native_to_hash_array(array)
      array.map { |i| `Opal.Hash.$new(i)` }
    end

    def lower_camelize(snake_cased_word)
      words = snake_cased_word.split('_')
      result = [words.first]
      result.concat(words[1..-1].map {|word| word[0].upcase + word[1..-1] }).join('')
    end

    def options_to_native(options)
      return unless options
      if options.has_key?(:filter)
        block = options[:filter]
        options[:filter] = %x{
          function(item) {
            return #{block.call(`Opal.Hash.$new(item)`)};
          }
        }
      end
      native_options = {}
      options.each do |key, value|
        native_options[lower_camelize(key)] = value
      end
      native_options.to_n
    end
  end
end