module Hyperloop
  class Component
    module Mixin
      def t(attribute)
        namespace = self.class.name.underscore.tr('/', '.')

        HyperI18n::I18n.t("#{namespace}.#{attribute}")
      end
    end
  end
end
