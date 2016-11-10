module ActiveRecord

  module ClassMethods

    def base_class

      unless self < Base
        raise ActiveRecordError, "#{name} doesn't belong in a hierarchy descending from ActiveRecord"
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
      base_class.instance_eval { @primary_key_value || :id }
    end

    def primary_key=(val)
     base_class.instance_eval {  @primary_key_value = val }
    end

    def inheritance_column
      base_class.instance_eval {@inheritance_column_value || "type"}
    end

    def inheritance_column=(name)
      base_class.instance_eval {@inheritance_column_value = name}
    end

    def model_name
      # in reality should return ActiveModel::Name object, blah blah
      name
    end

    def find(id)
      base_class.instance_eval {ReactiveRecord::Base.find(self, primary_key, id)}
    end

    def find_by(opts = {})
      base_class.instance_eval {ReactiveRecord::Base.find(self, opts.first.first, opts.first.last)}
    end

    def enum(*args)
      # when we implement schema validation we should also implement value checking
    end

    def method_missing(name, *args, &block)
      if args.count == 1 && name =~ /^find_by_/ && !block
        find_by(name.gsub(/^find_by_/, "") => args[0])
      else
        raise "#{self.name}.#{name}(#{args}) (called class method missing)"
      end
    end

    def abstract_class=(val)
      @abstract_class = val
    end

    def scope(name, body)
      singleton_class.send(:define_method, name) do | *args |
        args = (args.count == 0) ? name : [name, *args]
        ReactiveRecord::Base.class_scopes(self)[args] ||= ReactiveRecord::Collection.new(self, nil, nil, self, args)
      end
      singleton_class.send(:define_method, "#{name}=") do |collection|
        ReactiveRecord::Base.class_scopes(self)[name] = collection
      end
    end

    def all
      ReactiveRecord::Base.class_scopes(self)[:all] ||= ReactiveRecord::Collection.new(self, nil, nil, self, "all")
    end

    def all=(collection)
      ReactiveRecord::Base.class_scopes(self)[:all] = collection
    end

    # def server_methods(*methods)
    #   methods.each do |method|
    #     define_method(method) do |*args|
    #       if args.count == 0
    #         @backing_record.reactive_get!(method, :initialize)
    #       else
    #         @backing_record.reactive_get!([[method]+args], :initialize)
    #       end
    #     end
    #     define_method("#{method}!") do |*args|
    #       if args.count == 0
    #         @backing_record.reactive_get!(method, :force)
    #       else
    #         @backing_record.reactive_get!([[method]+args], :force)
    #       end
    #     end
    #   end
    # end
    #
    # alias_method :server_method, :server_methods

    [:belongs_to, :has_many, :has_one].each do |macro|
      define_method(macro) do |*args| # is this a bug in opal?  saying name, scope=nil, opts={} does not work!
        name = args.first
        opts = (args.count > 1 and args.last.is_a? Hash) ? args.last : {}
        Associations::AssociationReflection.new(self, macro, name, opts)
      end
    end

    def composed_of(name, opts = {})
      Aggregations::AggregationReflection.new(base_class, :composed_of, name, opts)
    end

    def column_names
      []  # it would be great to figure out how to get this information on the client!  For now we just return an empty array
    end

    def columns_hash
      HyperMesh::ClientDrivers.public_columns_hash[name] || {}
    end

    [
      "table_name=", "before_validation", "with_options", "validates_presence_of", "validates_format_of",
      "accepts_nested_attributes_for", "before_create", "after_create", "before_save", "after_save", "before_destroy", "where", "validate",
      "attr_protected", "validates_numericality_of", "default_scope", "has_attached_file", "attr_accessible",
      "serialize"
    ].each do |method|
      define_method(method.to_s) { |*args, &block| }
    end

    def _react_param_conversion(param, opt = nil)
      param = Native(param)
      param = JSON.from_object(param.to_n) if param.is_a? Native::Object
      result = if param.is_a? self
        param
      elsif param.is_a? Hash
        if opt == :validate_only
          klass = ReactiveRecord::Base.infer_type_from_hash(self, param)
          klass == self or klass < self
        else
          if param[primary_key]
            target = find(param[primary_key])
          else
            target = new
          end
          associations = reflect_on_all_associations
          param = param.collect do |key, value|
            assoc = reflect_on_all_associations.detect do |assoc|
              assoc.association_foreign_key == key
            end
            if assoc
              if value
                [assoc.attribute, {id: [value], type: [nil]}]
              else
                [assoc.attribute, [nil]]
              end
            else
              [key, [value]]
            end
          end
          ReactiveRecord::ServerDataCache.load_from_json(Hash[param], target)
          target
        end
      else
        nil
      end
      result
    end

  end

end
