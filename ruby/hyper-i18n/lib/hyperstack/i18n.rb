module Hyperstack
  module I18n
    def t(attribute, opts = {})
      namespace = self.class.name.underscore.gsub(%r{::|/}, '.')

      Hyperstack::Internal::I18n.t("#{namespace}.#{attribute}", opts)
    end

    def l(time, format = :default, opts = {})
      Hyperstack::Internal::I18n.l(time, format, opts)
    end
  end
end
