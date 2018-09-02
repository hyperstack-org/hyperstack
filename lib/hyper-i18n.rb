require 'hyperloop-config'
Hyperloop.import 'hyper-i18n'

require 'hyper-component'
require 'hyper-operation'

require 'hyper-i18n/helper_methods'
require 'hyper-i18n/operations/localize'
require 'hyper-i18n/operations/translate'
require 'hyper-i18n/i18n'

if RUBY_ENGINE == 'opal'
  require 'hyper-store'

  require 'hyper-i18n/active_model/name'
  require 'hyper-i18n/active_record/class_methods'
  require 'hyper-i18n/hyperloop/component/mixin'

  require 'hyper-i18n/stores/i18n_store'
else
  require 'opal'

  require 'hyper-i18n/version'

  Opal.append_path File.expand_path('../', __FILE__).untaint
end
