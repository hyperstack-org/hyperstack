module ActiveRecord
  module ClassMethods
    begin
      # Opal 0.11 super did not work with new, but new was defined
      alias _new_without_sti_type_cast new
      def new(*args, &block)
        _new_without_sti_type_cast(*args, &block).cast_to_current_sti_type
      end
    rescue NameError
      def self.extended(base)
        base.singleton_class.class_eval do
          alias_method :_new_without_sti_type_cast, :new
          define_method :new do |*args, &block|
            _new_without_sti_type_cast(*args, &block).cast_to_current_sti_type
          end
        end
      end
    end

    def base_class
      unless self < Base
        raise ActiveRecordError, "#{name} doesn't descend from ActiveRecord"
      end

      if superclass == Base || superclass.abstract_class?
        self
      else
        superclass.base_class
      end
    end

    def abstract_class?
      defined?(@abstract_class) && @abstract_class == true
    end

    def primary_key
      @primary_key_value ||= (self == base_class) ? :id : base_class.primary_key
    end

    def primary_key=(val)
      @primary_key_value = val.to_s
    end

    def inheritance_column
      return nil if @no_inheritance_column
      @inheritance_column_value ||=
        if self == base_class
          @inheritance_column_value || 'type'
        else
          superclass.inheritance_column.tap { |v| @no_inheritance_column = !v }
        end
    end

    def inheritance_column=(name)
      @no_inheritance_column = !name
      @inheritance_column_value = name
    end

    def model_name
      @model_name ||= ActiveModel::Name.new(self)
    end

    def __hyperstack_preprocess_attrs(attrs)
      if inheritance_column && self < base_class && !attrs.key?(inheritance_column)
        attrs = attrs.merge(inheritance_column => model_name.to_s)
      end
      dealiased_attrs = {}
      attrs.each { |attr, value| dealiased_attrs[_dealias_attribute(attr)] = value }
      dealiased_attrs
    end

    def find(*args)
      args = args[0] if args[0].is_a? Array
      return args.collect { |id| find(id) } if args.count > 1
      find_by(primary_key => args[0])
    end

    def find_by(attrs = {})
      attrs = __hyperstack_preprocess_attrs(attrs)
      # r = ReactiveRecord::Base.find_locally(self, attrs, new_only: true)
      # return r.ar_instance if r
      (r = __hyperstack_internal_scoped_find_by(attrs)) || return
      r.backing_record.sync_attributes(attrs).set_ar_instance!
    end

    def enum(*args)
      # when we implement schema validation we should also implement value checking
    end

    def serialize(attr, *args)
      ReactiveRecord::Base.serialized?[self][attr] = true
    end

    def _dealias_attribute(new)
      if self == base_class
        _attribute_aliases[new] || new
      else
        _attribute_aliases[new] ||= superclass._dealias_attribute(new)
      end
    end

    def _attribute_aliases
      @_attribute_aliases ||= {}
    end

    def alias_attribute(new_name, old_name)
      ['', '=', '_changed?'].each do |variant|
        define_method("#{new_name}#{variant}") { |*args, &block| send("#{old_name}#{variant}", *args, &block) }
      end
      _attribute_aliases[new_name] = old_name
    end

    # ignore any of these methods if they get called on the client.   This list should be trimmed down to include only
    # methods to be called as "macros" such as :after_create, etc...
    SERVER_METHODS = [
      :regulate_relationship, :regulate_scope,
      :attribute_type_decorations, :defined_enums, :_validators, :timestamped_migrations, :lock_optimistically, :lock_optimistically=,
      :local_stored_attributes=, :lock_optimistically?, :attribute_aliases?, :attribute_method_matchers?, :defined_enums?,
      :has_many_without_reactive_record_add_changed_method, :has_many_with_reactive_record_add_changed_method,
      :belongs_to_without_reactive_record_add_changed_method, :belongs_to_with_reactive_record_add_changed_method,
      :cache_timestamp_format, :composed_of_with_reactive_record_add_changed_method, :schema_format, :schema_format=,
      :error_on_ignored_order_or_limit, :error_on_ignored_order_or_limit=, :timestamped_migrations=, :dump_schema_after_migration,
      :dump_schema_after_migration=, :dump_schemas, :dump_schemas=, :warn_on_records_fetched_greater_than=,
      :belongs_to_required_by_default, :default_connection_handler, :connection_handler=, :default_connection_handler=,
      :skip_time_zone_conversion_for_attributes, :skip_time_zone_conversion_for_attributes=, :time_zone_aware_types,
      :time_zone_aware_types=, :protected_environments, :skip_time_zone_conversion_for_attributes?, :time_zone_aware_types?,
      :partial_writes, :partial_writes=, :composed_of_without_reactive_record_add_changed_method, :logger, :partial_writes?,
      :after_initialize, :record_timestamps, :record_timestamps=, :after_find, :after_touch, :before_save, :around_save,
      :belongs_to_required_by_default=, :default_connection_handler?, :before_create, :around_create, :before_update, :around_update,
      :after_save, :before_destroy, :around_destroy, :after_create, :after_destroy, :after_update, :_validation_callbacks,
      :_validation_callbacks?, :_validation_callbacks=, :_initialize_callbacks, :_initialize_callbacks?, :_initialize_callbacks=,
      :_find_callbacks, :_find_callbacks?, :_find_callbacks=, :_touch_callbacks, :_touch_callbacks?, :_touch_callbacks=, :_save_callbacks,
      :_save_callbacks?, :_save_callbacks=, :_create_callbacks, :_create_callbacks?, :_create_callbacks=, :_update_callbacks,
      :_update_callbacks?, :_update_callbacks=, :_destroy_callbacks, :_destroy_callbacks?, :_destroy_callbacks=, :record_timestamps?,
      :pre_synchromesh_scope, :pre_synchromesh_default_scope, :do_not_synchronize, :do_not_synchronize?,
      :logger=, :maintain_test_schema, :maintain_test_schema=, :scope, :time_zone_aware_attributes, :time_zone_aware_attributes=,
      :default_timezone, :default_timezone=, :_attr_readonly, :warn_on_records_fetched_greater_than, :configurations, :configurations=,
      :_attr_readonly?, :table_name_prefix=, :table_name_suffix=, :schema_migrations_table_name=, :internal_metadata_table_name,
      :internal_metadata_table_name=, :primary_key_prefix_type, :_attr_readonly=, :pluralize_table_names=, :protected_environments=,
      :ignored_columns=, :ignored_columns, :index_nested_attribute_errors, :index_nested_attribute_errors=, :primary_key_prefix_type=,
      :table_name_prefix?, :table_name_suffix?, :schema_migrations_table_name?, :internal_metadata_table_name?, :protected_environments?,
      :pluralize_table_names?, :ignored_columns?, :store_full_sti_class, :store_full_sti_class=, :nested_attributes_options,
      :nested_attributes_options=, :store_full_sti_class?, :default_scopes, :default_scope_override, :default_scopes=, :default_scope_override=,
      :nested_attributes_options?, :cache_timestamp_format=, :cache_timestamp_format?, :reactive_record_association_keys, :_validators=,
      :has_many, :belongs_to, :composed_of, :belongs_to_without_reactive_record_add_is_method, :_rollback_callbacks, :_commit_callbacks,
      :_before_commit_callbacks, :attribute_type_decorations=, :_commit_callbacks=, :_commit_callbacks?, :_before_commit_callbacks?,
      :_before_commit_callbacks=, :_rollback_callbacks=, :_before_commit_without_transaction_enrollment_callbacks?,
      :_before_commit_without_transaction_enrollment_callbacks=, :_commit_without_transaction_enrollment_callbacks,
      :_commit_without_transaction_enrollment_callbacks?, :_commit_without_transaction_enrollment_callbacks=, :_rollback_callbacks?,
      :_rollback_without_transaction_enrollment_callbacks?, :_rollback_without_transaction_enrollment_callbacks=,
      :_rollback_without_transaction_enrollment_callbacks, :_before_commit_without_transaction_enrollment_callbacks, :aggregate_reflections,
      :_reflections=, :aggregate_reflections=, :pluralize_table_names, :public_columns_hash, :attributes_to_define_after_schema_loads,
      :attributes_to_define_after_schema_loads=, :table_name_suffix, :schema_migrations_table_name, :attribute_aliases,
      :attribute_method_matchers, :connection_handler, :attribute_aliases=, :attribute_method_matchers=, :_validate_callbacks,
      :_validate_callbacks?, :_validate_callbacks=, :_validators?, :_reflections?, :aggregate_reflections?, :include_root_in_json,
      :_reflections, :include_root_in_json=, :include_root_in_json?, :local_stored_attributes, :default_scope, :table_name_prefix,
      :attributes_to_define_after_schema_loads?, :attribute_type_decorations?, :defined_enums=, :suppress, :has_secure_token,
      :generate_unique_secure_token, :store, :store_accessor, :_store_accessors_module, :stored_attributes, :reflect_on_aggregation,
      :reflect_on_all_aggregations, :_reflect_on_association, :reflect_on_all_associations, :clear_reflections_cache, :reflections,
      :reflect_on_association, :reflect_on_all_autosave_associations, :no_touching, :transaction, :after_commit, :after_rollback, :before_commit,
      :before_commit_without_transaction_enrollment, :after_create_commit, :after_update_commit, :after_destroy_commit,
      :after_commit_without_transaction_enrollment, :after_rollback_without_transaction_enrollment, :raise_in_transactional_callbacks,
      :raise_in_transactional_callbacks=, :accepts_nested_attributes_for, :has_secure_password, :has_one, :has_and_belongs_to_many,
      :before_validation, :after_validation, :serialize, :primary_key, :dangerous_attribute_method?, :get_primary_key, :quoted_primary_key,
      :define_method_attribute, :reset_primary_key, :primary_key=, :define_method_attribute=, :attribute_names, :initialize_generated_modules,
      :column_for_attribute, :define_attribute_methods, :undefine_attribute_methods, :instance_method_already_implemented?, :method_defined_within?,
      :dangerous_class_method?, :class_method_defined_within?, :attribute_method?, :has_attribute?, :generated_attribute_methods,
      :attribute_method_prefix, :attribute_method_suffix, :attribute_method_affix, :attribute_alias?, :attribute_alias, :define_attribute_method,
      :update_counters, :locking_enabled?, :locking_column, :locking_column=, :reset_locking_column, :decorate_attribute_type,
      :decorate_matching_attribute_types, :attribute, :define_attribute, :reset_counters, :increment_counter, :decrement_counter,
      :validates_absence_of, :validates_length_of, :validates_size_of, :validates_presence_of, :validates_associated, :validates_uniqueness_of,
      :validates_acceptance_of, :validates_confirmation_of, :validates_exclusion_of, :validates_format_of, :validates_inclusion_of,
      :validates_numericality_of, :define_callbacks, :normalize_callback_params, :__update_callbacks, :get_callbacks, :set_callback,
      :set_callbacks, :skip_callback, :reset_callbacks, :deprecated_false_terminator, :define_model_callbacks, :validate, :validators,
      :validates_each, :validates_with, :clear_validators!, :validators_on, :validates, :_validates_default_keys, :_parse_validates_options,
      :validates!, :_to_partial_path, :sanitize, :sanitize_sql, :sanitize_conditions, :quote_value, :sanitize_sql_for_conditions, :sanitize_sql_array,
      :sanitize_sql_for_assignment, :sanitize_sql_hash_for_assignment, :sanitize_sql_for_order, :expand_hash_conditions_for_aggregates, :sanitize_sql_like,
      :replace_named_bind_variables, :replace_bind_variables, :raise_if_bind_arity_mismatch, :replace_bind_variable, :quote_bound_value, :all,
      :default_scoped, :valid_scope_name?, :scope_attributes?, :before_remove_const, :ignore_default_scope?, :unscoped, :build_default_scope,
      :evaluate_default_scope, :ignore_default_scope=, :current_scope, :current_scope=, :scope_attributes, :base_class, :abstract_class?,
      :finder_needs_type_condition?, :sti_name, :descends_from_active_record?, :abstract_class, :compute_type, :abstract_class=, :table_name, :columns,
      :table_exists?, :columns_hash, :column_names, :attribute_types, :prefetch_primary_key?, :sequence_name, :quoted_table_name, :_default_attributes,
      :type_for_attribute, :inheritance_column, :attributes_builder, :inheritance_column=, :reset_table_name, :table_name=, :reset_column_information,
      :full_table_name_prefix, :full_table_name_suffix, :reset_sequence_name, :sequence_name=, :next_sequence_value, :column_defaults, :content_columns,
      :readonly_attributes, :attr_readonly, :create, :create!, :instantiate, :find, :type_caster, :arel_table, :find_by, :find_by!, :initialize_find_by_cache,
      :generated_association_methods, :arel_engine, :arel_attribute, :predicate_builder, :collection_cache_key, :relation_delegate_class,
      :initialize_relation_delegate_cache, :enum, :collecting_queries_for_explain, :exec_explain, :i18n_scope, :lookup_ancestors,
      :references, :uniq, :maximum, :none, :exists?, :second, :limit, :order, :eager_load, :update, :delete_all, :destroy, :ids, :many?, :pluck, :third,
      :delete, :fourth, :fifth, :forty_two, :second_to_last, :third_to_last, :preload, :sum, :take!, :first!, :last!, :second!, :offset, :select, :fourth!,
      :third!, :third_to_last!, :fifth!, :where, :first_or_create, :second_to_last!, :forty_two!, :first, :having, :any?, :one?, :none?, :find_or_create_by,
      :from, :first_or_create!, :first_or_initialize, :except, :find_or_create_by!, :find_or_initialize_by, :includes, :destroy_all, :update_all, :or,
      :find_in_batches, :take, :joins, :find_each, :last, :in_batches, :reorder, :group, :left_joins, :left_outer_joins, :rewhere, :readonly, :create_with,
      :distinct, :unscope, :calculate, :average, :count_by_sql, :minimum, :lock, :find_by_sql, :count, :cache, :uncached, :connection, :connection_pool,
      :establish_connection, :connected?, :clear_cache!, :clear_reloadable_connections!, :connection_id, :connection_config, :clear_all_connections!,
      :remove_connection, :connection_specification_name, :connection_specification_name=, :retrieve_connection, :connection_id=, :clear_active_connections!,
      :sqlite3_connection, :direct_descendants, :benchmark, :model_name, :with_options, :attr_protected, :attr_accessible
    ]

    def method_missing(name, *args, &block)
      if name == 'human_attribute_name'
        opts = args[1] || {}
        opts[:default] || args[0]
      elsif args.count == 1 && name.start_with?("find_by_") && !block
        find_by(name.sub(/^find_by_/, '') => args[0])
      elsif [].respond_to?(name)
        all.send(name, *args, &block)
      elsif name.end_with?('!')
        send(name.chop, *args, &block).send(:reload_from_db) rescue nil
      elsif !SERVER_METHODS.include?(name)
        raise "#{self.name}.#{name}(#{args}) (called class method missing)"
      end
    end

    # client side AR

    # Any method that can be applied to an array will be applied to the result
    # of all instead.
    # Any method ending with ! just means apply the method after forcing a reload
    # from the DB.

    def create(*args, &block)
      new(*args).save(&block)
    end

    def scope(name, *args)
      opts = _synchromesh_scope_args_check(args)
      scope_description = ReactiveRecord::ScopeDescription.new(self, name, opts)
      singleton_class.send(:define_method, name) do |*vargs|
        all.build_child_scope(scope_description, *name, *vargs)
      end
    end

    def default_scope(*args, &block)
      opts = _synchromesh_scope_args_check([*block, *args])
      @_default_scopes ||= []
      @_default_scopes << opts
    end

    def all
      ReactiveRecord::Base.default_scope[self] ||=
        begin
        root = ReactiveRecord::Collection
               .new(self, nil, nil, self, 'all')
               .extend(ReactiveRecord::UnscopedCollection)
        (@_default_scopes || [{ client: _all_filter }]).inject(root) do |scope, opts|
          scope.build_child_scope(ReactiveRecord::ScopeDescription.new(self, :all, opts))
        end
      end
    end

    def _all_filter
      # provides a filter for the all scopes taking into account STI subclasses
      # note: within the lambda `self` will be the model instance
      defining_class_is_base_class = base_class == self
      defining_model_name = model_name.to_s
      lambda do
        # have to delay computation of inheritance column since it might
        # not be defined when class is first defined
        ic = self.class.inheritance_column
        defining_class_is_base_class || !ic || self[ic] == defining_model_name
      end
    end

    def unscoped
      ReactiveRecord::Base.unscoped[self] ||=
        ReactiveRecord::Collection
        .new(self, nil, nil, self, 'unscoped')
        .extend(ReactiveRecord::UnscopedCollection)
    end

    def finder_method(name)
      ReactiveRecord::ScopeDescription.new(self, "_#{name}", {})
      [name, "#{name}!"].each do |method|
        singleton_class.send(:define_method, method) do |*vargs|
          collection = all.apply_scope("_#{method}", *vargs)
          collection.first
        end
      end
    end

    def abstract_class=(val)
      @abstract_class = val
    end

    # def scope(name, body)
    #   singleton_class.send(:define_method, name) do | *args |
    #     args = (args.count == 0) ? name : [name, *args]
    #     ReactiveRecord::Base.class_scopes(self)[args] ||= ReactiveRecord::Collection.new(self, nil, nil, self, args)
    #   end
    #   singleton_class.send(:define_method, "#{name}=") do |collection|
    #     ReactiveRecord::Base.class_scopes(self)[name] = collection
    #   end
    # end

    # def all
    #   ReactiveRecord::Base.class_scopes(self)[:all] ||= ReactiveRecord::Collection.new(self, nil, nil, self, "all")
    # end
    #
    # def all=(collection)
    #   ReactiveRecord::Base.class_scopes(self)[:all] = collection
    # end

    [:belongs_to, :has_many, :has_one].each do |macro|
      define_method(macro) do |*args| # is this a bug in opal?  saying name, scope=nil, opts={} does not work!
        name = args.first
        opts = (args.count > 1 and args.last.is_a? Hash) ? args.last : {}
        assoc = Associations::AssociationReflection.new(self, macro, name, opts)
        if macro == :has_many
          define_method(name) { @backing_record.get_has_many(assoc, nil) }
          define_method("_hyperstack_internal_setter_#{name}") { |val| @backing_record.set_has_many(assoc, val) }
        else
          define_method(name) { @backing_record.get_belongs_to(assoc, nil) }
          define_method("_hyperstack_internal_setter_#{name}") { |val| @backing_record.set_belongs_to(assoc, val) }
        end
        alias_method "#{name}=", "_hyperstack_internal_setter_#{name}"
        assoc
      end
    end

    def composed_of(name, opts = {})
      reflection = Aggregations::AggregationReflection.new(base_class, :composed_of, name, opts)
      if reflection.klass < ActiveRecord::Base
        define_method(name) { @backing_record.get_ar_aggregate(reflection, nil) }
        define_method("_hyperstack_internal_setter_#{name}") { |val| @backing_record.set_ar_aggregate(reflection, val) }
      else
        define_method(name) { @backing_record.get_non_ar_aggregate(name, nil) }
        define_method("_hyperstack_internal_setter_#{name}") { |val| @backing_record.set_non_ar_aggregate(reflection, val) }
      end
      alias_method "#{name}=", "_hyperstack_internal_setter_#{name}"
    end

    def column_names
      ReactiveRecord::Base.public_columns_hash.keys
    end

    def columns_hash
      ReactiveRecord::Base.public_columns_hash[name] || {}
    end

    def server_methods
      @server_methods ||= {}
    end

    def server_method(name, default: nil)
      server_methods[name] = { default: default }
      define_method(name) do |*args|
        vector = args.count.zero? ? name : [[name] + args]
        @backing_record.get_server_method(vector, nil)
      end
      define_method("#{name}!") do |*args|
        vector = args.count.zero? ? name : [[name] + args]
        @backing_record.get_server_method(vector, true)
      end
      define_method("_hyperstack_internal_setter_#{name}") do |val|
        backing_record.set_attr_value(name, val)
      end
    end

    # define all the methods for each column.  To allow overriding the methods they will NOT
    # be defined if already defined (i.e. by the model)  See the instance_methods module for how
    # super calls are handled in this case.   The _hyperstack_internal_setter_... methods
    # are used by the load_from_json method when bringing in data from the server, and so therefore
    # does not want to be overriden.

    def define_attribute_methods
      columns_hash.each do |name, column_hash|
        next if name == :id
        # only add serialized key if its serialized.  This just makes testing a bit
        # easier by keeping the columns_hash the same if there are no seralized strings
        # see rspec ./spec/batch1/column_types/column_type_spec.rb:100
        column_hash[:serialized?] = true if ReactiveRecord::Base.serialized?[self][name]

        define_method(name) { @backing_record.get_attr_value(name, nil) } unless method_defined?(name)
        define_method("#{name}!") { @backing_record.get_attr_value(name, true) } unless method_defined?("#{name}!")
        define_method("_hyperstack_internal_setter_#{name}") { |val| @backing_record.set_attr_value(name, val) }
        alias_method "#{name}=", "_hyperstack_internal_setter_#{name}" unless method_defined?("#{name}=")
        define_method("#{name}_changed?") { @backing_record.changed?(name) } unless method_defined?("#{name}_changed?")
        define_method("#{name}?") { @backing_record.get_attr_value(name, nil).present? } unless method_defined?("#{name}?")
      end
      self.inheritance_column = nil if inheritance_column && !columns_hash.key?(inheritance_column)
    end

    def _react_param_conversion(param, opt = nil)
      param = Native(param)
      param = JSON.from_object(param.to_n) if param.is_a? Native::Object
      result =
        if param.is_a? self
          param
        elsif param.is_a? Hash
          if opt == :validate_only
            klass = ReactiveRecord::Base.infer_type_from_hash(self, param)
            klass == self || klass < self
          else
            # TODO: investigate saving .changes here and then replacing the
            # TODO: changes after the load is complete.  In other words preserve the
            # TODO: changed values as changes while just updating the synced values.
            target =
              if param[primary_key]
                ReactiveRecord::Base.find(self, primary_key => param[primary_key]).tap do |r|
                  r.backing_record.loaded_id = param[primary_key]
                end
              else
                new
              end

            associations = reflect_on_all_associations

            already_processed_keys = Set.new

            param = param.collect do |key, value|
              next if already_processed_keys.include? key

              model_name = model_id = nil

              # polymorphic association is where the belongs_to side holds the
              # id, and the type of the model the id points to

              # belongs_to :duplicate_of, class_name: 'Report', required: false
              # has_many :duplicates, class_name: 'Report', foreign_key: 'duplicate_of_id'

              assoc = associations.detect do |poly_assoc|
                if key == poly_assoc.polymorphic_type_attribute
                  model_name = value
                  already_processed_keys << poly_assoc.association_foreign_key
                elsif key == poly_assoc.association_foreign_key && (poly_assoc.polymorphic_type_attribute || poly_assoc.macro == :belongs_to)
                  model_id = value
                  already_processed_keys << poly_assoc.polymorphic_type_attribute
                end
              end

              if assoc
                if !value
                  [assoc.attribute, [nil]]
                elsif assoc.polymorphic?
                  model_id ||= param.detect { |k, *| k == assoc.association_foreign_key }&.last
                  model_id ||= target.send(assoc.attribute)&.id
                  if model_id.nil?
                    raise "Error in #{self.name}._react_param_conversion. \n"\
                          "Could not determine the id of #{assoc.attribute} of #{target.inspect}.\n"\
                          "It was not provided in the conversion data, "\
                          "and it is unknown on the client"
                  end
                  model_name ||= param.detect { |k, *| k == assoc.polymorphic_type_attribute }&.last
                  model_name ||= target.send(assoc.polymorphic_type_attribute)
                  unless Object.const_defined?(model_name)
                    raise "Error in #{self.name}._react_param_conversion. \n"\
                          "Could not determine the type of #{assoc.attribute} of #{target.inspect}.\n"\
                          "It was not provided in the conversion data, "\
                          "and it is unknown on the client"
                  end

                  [assoc.attribute, { id: [model_id], model_name: [model_name] }]
                else
                  [assoc.attribute, { id: [value]}]
                end
              else
                [*key, [value]]
              end
            end.compact
            ReactiveRecord::Base.load_data do
              ReactiveRecord::ServerDataCache.load_from_json(Hash[param], target)
            end
            target.cast_to_current_sti_type
          end
        end

      result
    end
  end
end
