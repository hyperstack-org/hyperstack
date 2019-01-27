# Feature Matrix
Table with Ruby (on Rails) features and the implemenatation status for Hyperstack/Opal.

jRuby is not working at this time as the `libv8` gem is not compatible with jRuby,
`therubyrhino` gem might work as an alternative.

| Feature     | Type            | Module        | Status   | Links          | Exsisting Documenation | Exsisting Server Implementations | Implemenation At** |
|-------------|-----------------|---------------|----------|----------------|------------------------|----------------------------------|--------------------|
| new_record? | instance method | ActiveRecord  | missing  | Github issues? | [new_record?@apidock](https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-new_record-3F) |  | [hyper-model](https://github.com/hyperstack-org/hyperstack/blob/edge/ruby/hyper-model/lib/reactive_record/active_record/instance_methods.rb) |
| find        | class method    | ActiveRecord  | buged?   | [reproducable example](https://github.com/Tim-Blokdijk/hyperstack-experiments/blob/master/app/hyperstack/components/search.rb) |  |  | [hyper-model](https://github.com/hyperstack-org/hyperstack/blob/edge/ruby/hyper-model/lib/reactive_record/active_record/class_methods.rb) |
| destroy     | instance method | ActiveRecord  | buged?   | [reproducable example](https://github.com/Tim-Blokdijk/hyperstack-experiments/blob/master/app/hyperstack/components/index.rb) |  |  | [hyper-model](https://github.com/hyperstack-org/hyperstack/blob/edge/ruby/hyper-model/lib/reactive_record/active_record/instance_methods.rb) |
| DateTime    | class           | StdLib        | missing  |                | [DateTime@ruby-doc](https://ruby-doc.org/stdlib-2.6/libdoc/date/rdoc/DateTime.html) |  | Opal |
| truncate    | instance method | ActiveSupport | missing  |                | [truncate@apidock](https://apidock.com/rails/String/truncate) |  | [opal-activesupport@github](https://github.com/opal/opal-activesupport/tree/master/opal/active_support/core_ext) |
| i18n        | lib             | Rails-I18N    | basic    |                |                        | [rails-i18n@github](https://github.com/svenfuchs/rails-i18n) | [hyper-i18n](https://github.com/hyperstack-org/hyperstack/tree/edge/ruby/hyper-i18n) |

** Implemenation At: If `Status` is `missing` the place (file or directory) where the code should probably be impemented. Otherwise the actual implemenation.
