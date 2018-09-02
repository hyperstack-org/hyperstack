module Hyperloop
  def self.on_client?
    !(`typeof Opal.global.document === 'undefined'`) if RUBY_ENGINE == 'opal'
  end
end
