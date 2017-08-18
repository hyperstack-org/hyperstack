module ActiveRecord
  class Base
    def model_name
      @model_name ||= ActiveModel::Name.new(self)
    end

    def human_attribute_name(attribute)
      HyperI18n::I18n.t("activerecord.attributes.#{self.class.name.underscore}.#{attribute}")
    end
  end
end
