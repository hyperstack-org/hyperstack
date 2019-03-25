if RUBY_ENGINE == 'opal'
  module I18n
    class << self
      def t(*args)
        Hyperstack::Internal::I18n.t(*args)
      end
      def l(*args)
        Hyperstack::Internal::I18n.l(*args)
      end
    end
  end
end
