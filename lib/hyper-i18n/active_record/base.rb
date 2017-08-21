module ActiveRecord
  class Base
    def model_name
      @model_name ||= ActiveModel::Name.new(self)
    end

    def human_attribute_name(attribute, opts = {})
      attribute = "activerecord.attributes.#{self.class.name.underscore}.#{attribute}"

      HyperI18n::I18n.t(attribute, opts)
    end
  end
end
