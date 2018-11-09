module Hyperstack
  module Internal
    class I18n
      class Store
        include Hyperstack::State::Observable
        class << self
          observer(:translations)  { @translations ||= {} }
          observer(:localizations) { @localizations ||= {} }
          state_writer :translations, :localizations
        end
      end
    end
  end
end
