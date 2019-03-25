module ActiveModel
  # minimal ActiveModel definitions so we can support I18n methods
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
  end
end
