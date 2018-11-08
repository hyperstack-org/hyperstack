module HyperI18n
  class I18nStore
    include Hyperstack::State::Observable
    class << self
      observer(:translations)  { @translations ||= {} }
      observer(:localizations) { @localizations ||= {} }
      state_writer :translations, :localizations
    end
  end
end
