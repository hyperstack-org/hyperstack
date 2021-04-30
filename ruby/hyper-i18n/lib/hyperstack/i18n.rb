module Hyperstack
  module I18n
    class MissingTranslationError < StandardError; end

    def t(key, opts = {})
      namespace = self.class.name.underscore.gsub(%r{::|/}, ".")

      translation = Hyperstack::Internal::I18n.t("#{namespace}.#{key}", opts)

      # If intially not found and has components namespace, see if it's set without it
      if translation_missing?(translation) && translation =~ /components\./
        namespace = namespace.gsub("components.", "")

        translation = Hyperstack::Internal::I18n.t("#{namespace}.#{key}", opts)
      end

      # If translation is still not found, try looking up just the key provided
      if translation_missing?(translation)
        translation = Hyperstack::Internal::I18n.t(key, opts)
      end

      if translation_missing?(translation)
        raise MissingTranslationError, "Missing translation: #{namespace}.#{key}"
      end

      translation
    rescue MissingTranslationError => e
      # In the case of a missing translation return titleized key

      # HACK: In hyper-operation, String#titleize is patched to return the string as-is,
      #   so for now we have to manually titleize it
      # TODO: Switch to use String#titleize if hyper-operation removes that patch
      key.rpartition(".")[-1].split("_").map(&:capitalize).join(" ")
    end

    def l(time, format = :default, opts = {})
      Hyperstack::Internal::I18n.l(time, format, opts)
    end

    protected

    def translation_missing?(translation)
      translation.is_a?(String) && translation =~ /^translation missing:/
    end
  end
end
