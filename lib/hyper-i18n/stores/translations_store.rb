module HyperI18n
  class TranslationsStore < Hyperloop::Store
    state translations: {}, scope: :class, reader: true
  end
end
