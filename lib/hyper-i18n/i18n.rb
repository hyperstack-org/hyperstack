module HyperI18n
  class I18n
    include React::IsomorphicHelpers

    before_first_mount do
      if RUBY_ENGINE != 'opal'
        @server_data_cache = {}
      else
        unless `typeof window.HyperI18nInitialData === 'undefined'`
          JSON.from_object(`window.HyperI18nInitialData`).each do |attribute, translation|
            new_translations = TranslationsStore.translations.merge(:"#{attribute}" => translation)

            TranslationsStore.mutate.translations(new_translations)
          end
        end
      end
    end

    isomorphic_method(:t) do |f, attribute, default = ''|
      f.when_on_client do
        return TranslationsStore.translations[attribute] if TranslationsStore.translations[attribute]

        Translate
          .run(attribute: attribute)
          .then do |translation|
            new_translations = TranslationsStore.translations.merge(:"#{attribute}" => translation)
            TranslationsStore.mutate.translations(new_translations)
          end
      end

      f.when_on_server do
        @server_data_cache[attribute] = ::I18n.t(attribute, default)
      end
    end

    if RUBY_ENGINE != 'opal'
      prerender_footer do
        json = @server_data_cache.to_json

        %(<script type="text/javascript">
            if (typeof window.HyperI18nInitialData === 'undefined') {
              window.HyperI18nInitialData = #{json};
            }
          </script>)
      end
    end
  end
end
