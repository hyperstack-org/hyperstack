module Vis
  module Utilities
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
      native_options = {}
      options.each do |key, value|
        native_options[lower_camelize(key)] = value
      end
      native_options.to_n
    end
  end
end