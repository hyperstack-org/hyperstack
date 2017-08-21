module HyperI18n
  class I18n
    include React::IsomorphicHelpers

    before_first_mount do
      if RUBY_ENGINE != 'opal'
        @server_data_cache = { t: {}, l: {} }
      else
        unless no_initial_data?
          JSON.from_object(`window.HyperI18nInitialData.t`).each do |attribute, translation|
            I18nStore.translations[attribute] = translation
          end

          JSON.from_object(`window.HyperI18nInitialData.l`).each do |time, localization|
            I18nStore.localizations[time] = localization
          end
        end
      end
    end

    isomorphic_method(:t) do |f, attribute, default = ''|
      f.when_on_client do
        return I18nStore.translations[attribute] if I18nStore.translations[attribute]

        Translate
          .run(attribute: attribute)
          .then do |translation|
            I18nStore.translations[attribute] = translation
            I18nStore.mutate.translations(I18nStore.translations)
          end
      end

      f.when_on_server do
        @server_data_cache[:t][attribute] = ::I18n.t(attribute, default)
      end
    end

    isomorphic_method(:l) do |f, time, format = :default|
      time = Time.parse(time.to_s)
      format = :"#{format}" unless format =~ /%/

      f.when_on_client do
        return I18nStore.localizations[time][format] if I18nStore.localizations[time] &&
                                                        I18nStore.localizations[time][format]

        Localize
          .run(time: time, format: format)
          .then do |localization|
            I18nStore.localizations[time] ||= {}
            I18nStore.localizations[time][format] = localization

            I18nStore.mutate.localizations(I18nStore.localizations)
          end
      end

      f.when_on_server do
        @server_data_cache[:l][time] ||= {}

        @server_data_cache[:l][time][format] = ::I18n.l(time, format: format)
      end
    end

    if RUBY_ENGINE != 'opal'
      prerender_footer do
        json =
          if @server_data_cache
            @server_data_cache.as_json.to_json
          else
            {}.to_json
          end

        "<script type=\"text/javascript\">\n"\
          "if (typeof window.HyperI18nInitialData === 'undefined') {\n"\
          "  window.HyperI18nInitialData = #{json};\n"\
          "}\n"\
          "</script>\n"
      end
    end

    def self.no_initial_data?
      `typeof window.HyperI18nInitialData === 'undefined'`
    end
  end
end
