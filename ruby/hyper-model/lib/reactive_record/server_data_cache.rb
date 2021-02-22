require 'set'
module ReactiveRecord

  # requested cache items I think is there just so prerendering with multiple components works.
  # because we have to dump the cache after each component render (during prererender) but
  # we want to keep the larger cache alive (is this important???) we keep track of what got added
  # to the cache during this cycle

  # the point is to collect up a all records needed, with whatever attributes were required + primary key, and inheritance column
  # or get all scope arrays, with the record ids

  # the incoming vector includes the terminal method

  # output is a hash tree of the form
  # tree ::= {method => tree | [value]} |      method's value is either a nested tree or a single value which is wrapped in array
  #          {:id => primary_key_id_value} |   if its the id method we leave the array off because we know it must be an int
  #          {integer => tree}                 for collections, each item retrieved will be represented by its id
  #
  # example
  # {
  #   "User" => {
  #     ["find", 12] => {
  #       :id => 12
  #       "email" => ["mitch@catprint.com"]
  #       "todos" => {
  #         "active" => {
  #           123 =>
  #             {
  #               id: 123,
  #               title: ["get fetch_records_from_db done"]
  #             },
  #           119 =>
  #             {
  #               id: 119
  #               title: ["go for a swim"]
  #             }
  #            ]
  #          }
  #        }
  #       }
  #     }
  #   }
  # }

  # To build this tree we first fill values for each individual vector, saving all the intermediate data
  # when all these are built we build the above hash structure

  # basic
  # [Todo, [find, 123], title]
  # -> [[Todo, [find, 123], title], "get fetch_records_from_db done", 123]

  # [User, [find_by_email, "mitch@catprint.com"], first_name]
  # -> [[User, [find_by_email, "mitch@catprint.com"], first_name], "Mitch", 12]

  # misses
  # [User, [find_by_email, "foobar@catprint.com"], first_name]
  #   nothing is found so nothing is downloaded
  # prerendering may do this
  # [User, [find_by_email, "foobar@catprint.com"]]
  #   which will return a cache object whose id is nil, and value is nil

  # scoped collection
  # [User, [find, 12], todos, active, *, title]
  # -> [[User, [find, 12], todos, active, *, title], "get fetch_records_from_db done", 12, 123]
  # -> [[User, [find, 12], todos, active, *, title], "go for a swim", 12, 119]

  # collection with nested belongs_to
  # [User, [find, 12], todos, *, team]
  # -> [[User, [find, 12], todos, *, team, name], "developers", 12, 123, 252]
  #    [[User, [find, 12], todos, *, team, name], nil, 12, 119]  <- no team defined for todo<119> so list ends early

  # collections that are empty will deliver nothing
  # [User, [find, 13], todos, *, team, name]   # no todos for user 13
  #   evaluation will get this far: [[User, [find, 13], todos], nil, 13]
  #   nothing will match [User, [find, 13], todos, team, name] so nothing will be downloaded


  # aggregate
  # [User, [find, 12], address, zip_code]
  # -> [[User, [find, 12], address, zip_code]], "14622", 12] <- note parent id is returned

  # aggregate with a belongs_to
  # [User, [find, 12], address, country, country_code]
  # -> [[User, [find, 12], address, country, country_code], "US", 12, 342]

  # collection * (for iterators etc)
  # [User, [find, 12], todos, overdue, *all]
  # -> [[User, [find, 12], todos, active, *all], [119, 123], 12]

  # [Todo, [find, 119], owner, todos, active, *all]
  # -> [[Todo, [find, 119], owner, todos, active, *all], [119, 123], 119, 12]

    class ServerDataCache

      def initialize(acting_user, preloaded_records)
        @acting_user = acting_user
        @cache = []
        @cache_reps = {}
        @requested_cache_items = Set.new
        @preloaded_records = preloaded_records
      end

      attr_reader :cache
      attr_reader :cache_reps
      attr_reader :requested_cache_items

      def add_item_to_cache(item)
        cache << item
        cache_reps[item.vector] = item
        requested_cache_items << item
      end

      if RUBY_ENGINE != 'opal'

        def self.get_model(str)
          # We don't want to open a security hole by allowing some client side string to
          # autoload a class, which would happen if we did a simple str.constantize.
          #
          # Because all AR models are loaded at boot time on the server to define the
          # ActiveRecord::Base.public_columns_hash method any model which the client has
          # access to should already be loaded.
          #
          # If str is not already loaded then we have an access violation.
          unless const_defined? str
            Hyperstack::InternalPolicy.raise_operation_access_violation(:undefined_const, "#{str} is not a loaded constant")
          end
          str.constantize
        end

        def [](*vector)
          timing('building cache_items') do
            root = CacheItem.new(self, @acting_user, vector[0], @preloaded_records)
            vector[1..-1].inject(root) { |cache_item, method| cache_item.apply_method method if cache_item }
            final = vector[1..-1].inject(root) { |cache_item, method| cache_item.apply_method method if cache_item }
            next final unless final && final.value.respond_to?(:superclass) && final.value.superclass <= ActiveRecord::Base
            Hyperstack::InternalPolicy.raise_operation_access_violation(:invalid_vector, "attempt to insecurely access relationship #{vector.last}.")
          end
        end

        def start_timing(&block)
          ServerDataCache.start_timing(&block)
        end

        def timing(tag, &block)
          ServerDataCache.timing(tag, &block)
        end

        def self.start_timing(&block)
          @timings = Hash.new { |h, k| h[k] = 0 }
          start_time = Time.now
          yield.tap do
            ::Rails.logger.debug "********* Total Time #{total = Time.now - start_time} ***********************"
            sum = 0
            @timings.sort_by(&:last).reverse.each do |tag, time|
              ::Rails.logger.debug "            #{tag}: #{time} (#{(time/total*100).to_i})%"
              sum += time
            end
            ::Rails.logger.debug "********* Other Time ***********************"
          end
        end

        def self.timing(tag, &block)
          start_time = Time.now
          tag = tag.to_sym
          yield.tap { @timings[tag] += (Time.now - start_time) if @timings }
        end

        def self.[](models, associations, vectors, acting_user)
          start_timing do
            timing(:public_columns_hash) { ActiveRecord::Base.public_columns_hash }
            result = nil
            ActiveRecord::Base.transaction do
              cache = new(acting_user, timing(:save_records) { ReactiveRecord::Base.save_records(models, associations, acting_user, false, false) })
              timing(:process_vectors) { vectors.each { |vector| cache[*vector] } }
              timing(:as_json) { result = cache.as_json }
              raise ActiveRecord::Rollback, "This Rollback is intentional!"
            end
            result
          end
        end

        def clear_requests
          @requested_cache_items = Set.new
        end

        def as_json
          @requested_cache_items.inject({}) do |hash, cache_item|
            hash.deep_merge! cache_item.as_hash
          end
        end

        def select(&block); @cache.select(&block); end

        def detect(&block); @cache.detect(&block); end

        def inject(initial, &block); @cache.inject(initial) &block; end

        class CacheItem

          attr_reader :vector
          attr_reader :absolute_vector
          attr_reader :root
          attr_reader :acting_user

          def value
            @value # which is a ActiveRecord object
          end

          def method
            @vector.last
          end

          def self.new(db_cache, acting_user, klass, preloaded_records)
            klass = ServerDataCache.get_model(klass)
            if existing = ServerDataCache.timing(:root_lookup) { db_cache.cache.detect { |cached_item| cached_item.vector == [klass] } }
              return existing
            end
            super
          end

          def initialize(db_cache, acting_user, klass, preloaded_records)
            @db_cache = db_cache
            @acting_user = acting_user
            @vector = @absolute_vector = [klass]
            @value = klass
            @parent = nil
            @root = self
            @preloaded_records = preloaded_records
            @db_cache.add_item_to_cache self
          end

          def to_s
            acting_user_string =
              if acting_user
                " - with acting user: <#{acting_user.class.name} id: #{acting_user.id}>"
              else
                ' - with no acting user'
              end
            vector.collect do |e|
              if e.is_a? String
                e
              elsif e.is_a? Array
                e.length > 1 ? "#{e.first}(#{e[1..-1].join(', ')})" : e.first
              else
                e.name
              end
            end.join('.') + acting_user_string
          rescue
            vector.to_s + acting_user_string
          end

          def start_timing(&block)
            ServerDataCache.class.start_timing(&block)
          end

          def timing(tag, &block)
            ServerDataCache.timing(tag, &block)
          end

          def apply_method_to_cache(method)
            @db_cache.cache.inject(nil) do |representative, cache_item|
              if cache_item.vector == vector
                begin
                  # error_recovery_method holds the current method that we are attempting to apply
                  # in case we throw an exception, and need to give the developer a meaningful message.
                  if method == "*"
                    # apply_star does the security check if value is present
                    cache_item.apply_star || representative
                  elsif method == "*all"
                    # if we secure the collection then we assume its okay to read the ids
                    error_recovery_method = [:all]
                    secured_value = cache_item.value.__secure_collection_check(cache_item)
                    cache_item.build_new_cache_item(timing(:active_record) { secured_value.collect { |record| record.id } }, method, method)
                  elsif method == "*count"
                    error_recovery_method = [:count]
                    secured_value = cache_item.value.__secure_collection_check(cache_item)
                    cache_item.build_new_cache_item(timing(:active_record) { cache_item.value.__secure_collection_check(cache_item).count }, method, method)
                  elsif preloaded_value = @preloaded_records[cache_item.absolute_vector + [method]]
                    # no security check needed since we already evaluated this
                    cache_item.build_new_cache_item(preloaded_value, method, method)
                  elsif aggregation = cache_item.aggregation?(method)
                    # aggregations are not protected
                    error_recovery_method = [method, :mapping, :all]
                    cache_item.build_new_cache_item(aggregation.mapping.collect { |attribute, accessor| cache_item.value[attribute] }, method, method)
                  else
                    if !cache_item.value || cache_item.value.is_a?(Array)
                      # seeing as we just returning representative, no check is needed (its already checked)
                      representative
                    elsif method == 'model_name'
                      error_recovery_method = [:model_name]
                      cache_item.build_new_cache_item(timing(:active_record) { cache_item.value.model_name }, method, method)
                    else
                      begin
                        secured_method = "__secure_remote_access_to_#{[*method].first}"
                        error_recovery_method = [*method]
                        # order is important.  This check must be first since scopes can have same name as attributes!
                        if cache_item.value.respond_to? secured_method
                          cache_item.build_new_cache_item(timing(:active_record) { cache_item.value.send(secured_method, cache_item.value, @acting_user, *([*method][1..-1])) }, method, method)
                        elsif (cache_item.value.class < ActiveRecord::Base) && cache_item.value.attributes.has_key?(method) # TODO: second check is not needed, its built into  check_permmissions,  check should be does class respond to check_permissions...
                          cache_item.value.check_permission_with_acting_user(@acting_user, :view_permitted?, method)
                          cache_item.build_new_cache_item(timing(:active_record) { cache_item.value.send(*method) }, method, method)
                        else
                          raise "Method missing while fetching data: \`#{[*method].first}\` "\
                          'was expected to be an attribute or a method defined using the server_method of finder_method macros.'
                        end
                      end
                    end
                  end
                rescue StandardError => e
                  raise e.class, form_error_message(e, cache_item.vector + error_recovery_method), e.backtrace
                end
              else
                representative
              end
            end
          end

          def form_error_message(original_error, vector)
            expression = vector.collect do |exp|
              next exp unless exp.is_a? Array
              next exp.first if exp.length == 1
              "#{exp.first}(#{exp[1..-1].join(', ')})"
            end.join('.')
            "raised when evaluating #{expression}\n#{original_error}"
          end

          def aggregation?(method)
            if method.is_a?(String) && @value.class.respond_to?(:reflect_on_aggregation)
              aggregation = @value.class.reflect_on_aggregation(method.to_sym)
              if aggregation && !(aggregation.klass < ActiveRecord::Base) && @value.send(method)
                aggregation
              end
            end
          end

          def apply_star
            if @value && @value.__secure_collection_check(self) && @value.length > 0
              i = -1
              @value.inject(nil) do |representative, current_value|
                i += 1
                if preloaded_value = @preloaded_records[@absolute_vector + ["*#{i}"]]
                  build_new_cache_item(preloaded_value, "*", "*#{i}")
                else
                  build_new_cache_item(current_value, "*", "*#{i}")
                end
              end
            else
              build_new_cache_item([], "*", "*")
            end
          end

          # TODO replace instance_eval with a method like clone_new_child(....)
          def build_new_cache_item(new_value, method, absolute_method)
            new_parent = self
            self.clone.instance_eval do
              @vector = @vector + [method]  # don't push it on since you need a new vector!
              @absolute_vector = @absolute_vector + [absolute_method]
              @value = new_value
              @db_cache.add_item_to_cache self
              @parent = new_parent
              @root = new_parent.root
              self
            end
          end

          def apply_method(method)
            if method.is_a? Array and method.first == "find_by_id"
              method[0] = "find"
            elsif method.is_a? String and method =~ /^\*[0-9]+$/
              method = "*"
            end
            new_vector = vector + [method]
            timing('apply_method lookup') { @db_cache.cache_reps[new_vector] } || apply_method_to_cache(method)
          end

          def jsonize(method)
            # sadly standard json converts {[:foo, nil] => 123} to {"['foo', nil]": 123}
            # luckily [:foo, nil] does convert correctly
            # so we check the methods and force proper conversion
            method.is_a?(Array) ? method.to_json : method
          end

          def merge_inheritance_column(children)
            if @value.attributes.key? @value.class.inheritance_column
              children[@value.class.inheritance_column] = [@value[@value.class.inheritance_column]]
            end
            children
          end

          def as_hash(children = nil)
            unless children
              return {} if @value.is_a?(Class) && (@value < ActiveRecord::Base)
              children = [@value.is_a?(BigDecimal) ? @value.to_f : @value]
            end
            if @parent
              if method == "*"
                if @value.is_a? Array  # this happens when a scope is empty there is test case, but
                  @parent.as_hash({})  # does it work for all edge cases?
                elsif (@value.class < ActiveRecord::Base) && children.is_a?(Hash)
                  @parent.as_hash({@value.id => merge_inheritance_column(children)})
                else
                  @parent.as_hash({@value.id => children})
                end
              elsif (@value.class < ActiveRecord::Base) && children.is_a?(Hash)
                id = method.is_a?(Array) && method.first == "new" ? [nil] : [@value.id]
                # c = children.merge(id: id)
                # if @value.attributes.key? @value.class.inheritance_column
                #   c[@value.class.inheritance_column] = [@value[@value.class.inheritance_column]]
                # end
                @parent.as_hash(jsonize(method) => merge_inheritance_column(children.merge(id: id)))
              elsif method == '*all'
                @parent.as_hash('*all' => children.first)
              else
                @parent.as_hash(jsonize(method) => children)
              end
            else
              { method.name => children }
            end
          end

          def to_json
            @value.to_json
          end

        end

      end

=begin
tree is a hash, target is the object that will be filled in with the data hanging off the key.
first time around target == nil, so for each key, value pair we do this: load_from_json(value, Object.const_get(JSON.parse(key)))
keys:
  ':*all':   target.replace tree["*all"].collect { |id| target.proxy_association.klass.find(id) }
  Example: {'*all': [1, 7, 19, 23]}  target is a collection and will now have 4 records: 1, 7, 19, 23

  'id':  if value is an array then target.id = value.first
  Example: {'id': [17]} Example the target is a record, and its id is now set to 17

  '*count': target.set_count_state(value.first)  note: set_count_state sets the count of a collection and updates the associated state variable
  integer-like-string-or-number: target.push_and_update_belongs_to(key)  note: collection will be a has_many association, so we are doing a target << find(key), and updating both ends of the relationship
  [:new, nnn] do a ReactiveRecord::Base.find_by_object_id(target.base_class, method[1]) and that becomes the new target, with val being passed allow_change
  [...] and current target is NOT an ActiveRecord Model (??? a collection ???) then send key to target, and that becomes new target
      but note if value is an array then the scope returned nil, so we destroy the bogus record, and set new target back to nil
        new_target.destroy and new_target = nil if value.is_a? Array
  [...] and current target IS AN ActiveRecord Model (not a collection) then target.backing_record.update_attribute([method], target.backing_record.convert(method, value.first))
  aggregation:
    target.class.respond_to?(:reflect_on_aggregation) and aggregation = target.class.reflect_on_aggregation(method) and !(aggregation.klass < ActiveRecord::Base)
      target.send "#{method}=", aggregation.deserialize(value.first)
  other-string-method-name:
    if value is a an array then value.first is the new value and we do target.send "{key}=", value.first
    if value is a hash
=end

      def self.load_from_json(tree, target = nil)
        # have to process *all before any other items
        # we leave the "*all" key in just for debugging purposes, and then skip it below

        if sorted_collection = tree["*all"]
          loaded_collection = sorted_collection.collect do |id|
            ReactiveRecord::Base.find_by_id(target.proxy_association.klass, id)
          end
          if loaded_collection[0] && target.scope_description&.name == '___hyperstack_internal_scoped_find_by'
            primary_key = target.proxy_association.klass.primary_key
            attrs = target.vector[-1][1].reject { |key, _| key == primary_key }
            loaded_collection[0].backing_record.sync_attributes(attrs)
          end
          target.replace loaded_collection
          # we need to notify any observers of the collection.  collection#replace
          # will not notify if we are data_loading (which we are) so we will do it
          # here.  BUT we want the notification to occur after the current event
          # completes so we wrap it a bulk_update
          Hyperstack::Internal::State::Mapper.bulk_update do
            Hyperstack::Internal::State::Variable.set(target, :collection, target.collection)
          end
        end

        if (id_value = tree[target.class.try(:primary_key)]) && id_value.is_a?(Array)
          target.id = id_value.first
        end
        tree.each do |method, value|
          method = JSON.parse(method) rescue method
          new_target = nil

          if method == "*all"
            next # its already been processed above
          elsif !target
            load_from_json(value, Object.const_get(method))
          elsif method == "*count"
            target.set_count_state(value.first)
          elsif method.is_a? Integer or method =~ /^[0-9]+$/
            new_target = target.push_and_update_belongs_to(method)
          elsif method.is_a? Array
            if method[0] == "new"
              new_target = ReactiveRecord::Base.lookup_by_object_id(method[1])
            elsif !(target.class < ActiveRecord::Base)
              new_target = target.send(*method)
              # value is an array if scope returns nil, so we destroy the bogus record
              new_target.destroy && (new_target = nil) if value.is_a? Array
            else
              target.backing_record.update_simple_attribute([method], target.backing_record.convert(method, value.first))
            end
          elsif target.class.respond_to?(:reflect_on_aggregation) &&
                (aggregation = target.class.reflect_on_aggregation(method)) &&
                !(aggregation.klass < ActiveRecord::Base)
            value = [aggregation.deserialize(value.first)] unless value.first.is_a?(aggregation.klass)

            target.send "#{method}=", value.first
          elsif value.is_a? Array
            target.send("_hyperstack_internal_setter_#{method}", value.first) unless method == target.class.primary_key
          elsif value.is_a?(Hash) && value[:id] && value[:id].first && (association = target.class.reflect_on_association(method))
            # not sure if its necessary to check the id above... is it possible to for the method to be an association but not have an id?
            klass = value[:model_name] ? Object.const_get(value[:model_name].first) : association.klass
            new_target = ReactiveRecord::Base.find_by_id(klass, value[:id].first)
            target.send "#{method}=", new_target
          elsif !(target.class < ActiveRecord::Base)
            new_target = target.send(*method)
            # value is an array if scope returns nil, so we destroy the bogus record
            new_target.destroy and new_target = nil if value.is_a? Array
          else
            new_target = target.send("#{method}=", target.send(method))
          end
          load_from_json(value, new_target) if new_target
        end
      rescue Exception => e
        raise e
      end
    end
  end
