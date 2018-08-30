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

      def test_container
        `document.body.appendChild(document.createElement('div'))`
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

    def lower_camelize_hash(hash)
      camel_hash = {}
      hash.each do |key, value|
        value = lower_camelize_hash(value) if `Opal.is_a(value, Opal.Hash)`
        camel_hash[lower_camelize(key)] = value
      end
      camel_hash
    end
  end
end
