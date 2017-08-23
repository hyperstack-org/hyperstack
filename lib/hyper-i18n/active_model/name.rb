# TODO: This should really be in hyper-mesh
module ActiveModel
  class Name
    attr_reader :name, :klass, :i18n_key

    def initialize(klass)
      @name     = klass.name
      @klass    = klass
      @i18n_key = :"#{@name.underscore}"
    end

    def to_s
      @name
    end

    def human
      HyperI18n::I18n.t("activerecord.models.#{i18n_key}")
    end
  end
end
