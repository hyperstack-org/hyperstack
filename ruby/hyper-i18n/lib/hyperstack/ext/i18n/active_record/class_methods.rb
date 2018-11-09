module ActiveRecord
  module ClassMethods
    def human_attribute_name(attribute, opts = {})
      attribute = "activerecord.attributes.#{model_name.i18n_key}.#{attribute}"

      Hyperstack::Internal::I18n.t(attribute, opts)
    end
  end
end
