module HyperI18n
  class I18nStore < Hyperloop::Store
    state translations: {}, scope: :class, reader: true
    state localizations: {}, scope: :class, reader: true
  end
end
