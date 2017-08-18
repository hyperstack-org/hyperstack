require 'hyperloop-config'
Hyperloop.import 'hyper-i18n'

require 'hyper-component'
require 'hyper-operation'

require 'hyper-i18n/operations/translate'

if RUBY_ENGINE == 'opal'
  require 'hyper-store'

  require 'hyper-i18n/i18n'
  require 'hyper-i18n/active_model/name'
  require 'hyper-i18n/active_record/base'
  require 'hyper-i18n/hyperloop/component/mixin'

  require 'hyper-i18n/stores/translations_store'
else
  require 'opal'

  require 'hyper-i18n/i18n'
  require 'hyper-i18n/version'

  Opal.append_path File.expand_path('../', __FILE__).untaint
end
