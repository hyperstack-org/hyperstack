module Hyperloop
  class Component
    module Mixin
      def t(attribute, opts = {})
        namespace = self.class.name.underscore.gsub(%r{::|/}, '.')

        HyperI18n::I18n.t("#{namespace}.#{attribute}", opts)
      end

      def l(time, format = :default, opts = {})
        HyperI18n::I18n.l(time, format, opts)
      end
    end
  end
end
