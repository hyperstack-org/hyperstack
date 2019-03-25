require 'hyperstack-config'
Hyperstack.import 'hyper-i18n'

require 'hyper-component'
require 'hyper-operation'
require 'hyper-state'

require 'hyperstack/internal/i18n/helper_methods'
require 'hyperstack/internal/i18n/localize'
require 'hyperstack/internal/i18n/translate'
require 'hyperstack/internal/i18n'
require 'hyperstack/i18n/version'

if RUBY_ENGINE == 'opal'
  require 'hyperstack/ext/i18n/active_model/name'
  require 'hyperstack/ext/i18n/active_record/class_methods'
  require 'hyperstack/internal/i18n/store'
  require 'hyperstack/i18n'
  require 'hyperstack/i18n/i18n'
else
  require 'opal'

  Opal.append_path File.expand_path('../', __FILE__).untaint
end
