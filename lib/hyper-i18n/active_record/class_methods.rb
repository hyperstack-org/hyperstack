module ActiveRecord
  module ClassMethods
    # TODO: This should really be in hyper-mesh
    def model_name
      @model_name ||= ActiveModel::Name.new(self)
    end

    def human_attribute_name(attribute, opts = {})
      attribute = "activerecord.attributes.#{model_name.i18n_key}.#{attribute}"

      HyperI18n::I18n.t(attribute, opts)
    end
  end
end
