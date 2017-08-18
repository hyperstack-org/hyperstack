module ActiveModel
  class Name
    attr_accessor :i18n_key

    def initialize(record)
      @i18n_key = :"#{record.class.name.underscore}"
    end

    def human
      HyperI18n::I18n.t("activerecord.models.#{i18n_key}")
    end
  end
end
