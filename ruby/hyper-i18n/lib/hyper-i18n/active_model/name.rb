# TODO: This should really be in hyper-mesh
module ActiveModel
  class Name
    def human
      HyperI18n::I18n.t("activerecord.models.#{i18n_key}")
    end
  end
end
