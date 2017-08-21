module Hyperloop
  class Component
    module Mixin
      def t(attribute)
        namespace = self.class.name.underscore.tr('/', '.')

        HyperI18n::I18n.t("#{namespace}.#{attribute}")
      end

      def l(time, format = :default)
        HyperI18n::I18n.l(time, format)
      end
    end
  end
end
