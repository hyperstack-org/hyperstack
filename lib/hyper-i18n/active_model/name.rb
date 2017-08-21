module ActiveModel
  class Name
    attr_accessor :i18n_key

    def initialize(klass)
      @i18n_key = :"#{klass.name.underscore}"
    end

    def human
      HyperI18n::I18n.t("activerecord.models.#{i18n_key}")
    end
  end
end
