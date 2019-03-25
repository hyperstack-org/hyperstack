# TODO: This should really be in hyper-mesh
module ActiveModel
  class Name
    def human
      Hyperstack::Internal::I18n.t("activerecord.models.#{i18n_key}")
    end
  end
end
