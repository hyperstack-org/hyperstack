module ReactiveRecord
  # Keeps track of the details (client side) of a scope.
  # The main point is to provide knowledge of what models
  # the scope is joined with, and the client side
  # filter proc
  class ScopeDescription
    def initialize(model, name, opts)
      ScopeDescription.all[model][name] = self
      @filter_proc = filter_proc(opts)
      @name = name
      @model = model
      build_joins opts[:joins]
    end

    def self.all
      @all ||= Hash.new { |h, k| h[k] = {} }
    end

    def filter?
      @filter_proc.respond_to?(:call)
    end

    def collector?
      @is_collector
    end

    def joins_with?(record)
      @joins.detect do |klass, vector|
        vector.any? && (klass == :all || record.class == klass || record.class < klass)
      end
    end

    def related_records_for(record)
      ReactiveRecord::Base.catch_db_requests([]) do
        (@joins[record.class.base_class] || @joins[:all]).collect do |vector|
          crawl(record, *vector)
        end.flatten.compact
      end
    end

    def filter_records(related_records, args)
      if collector?
        Set.new(related_records.to_a.instance_exec(*args, &@filter_proc))
      else
        Set.new(related_records.select { |r| r.instance_exec(*args, &@filter_proc) })
      end
    end

    # private methods

    def filter_proc(opts)
      return true unless opts.key?(:client) || opts.key?(:select)
      client_opt = opts[:client] || opts[:select]
      @is_collector = opts.key?(:select)
      return client_opt if !client_opt || client_opt.respond_to?(:call)
      raise 'Scope option :client or :select must be a proc, false, or nil'
    end

    def build_joins(joins_list)
      if !@filter_proc || joins_list == []
        @joins = { all: [] }
      elsif joins_list.nil?
        @joins = { @model => [[]], all: [] }
      elsif joins_list == :all
        @joins = { all: [[]] }
      else
        joins_list = [joins_list] unless joins_list.is_a? Array
        map_joins_path joins_list
      end
    end

    def map_joins_path(paths)
      @joins = Hash.new { |h, k| h[k] = Array.new }.merge(@model => [[]])
      paths.each do |path|
        vector = []
        path.split('.').inject(@model) do |model, attribute|
          association = model.reflect_on_association(attribute)
          raise build_error(path, model, attribute) unless association
          vector = [association.inverse_of, *vector]
          @joins[association.klass] << vector
          association.klass
        end
      end
    end

    def build_error(path, model, attribute)
      "Could not find joins association '#{model.name}.#{attribute}' "\
      "for '#{path}' while processing scope #{@model.name}.#{@name}."
    end

    def crawl(item, method = nil, *vector)
      if !method && item.is_a?(Collection)
        item.all
      elsif !method
        item
      elsif item.respond_to? :collect
        item.collect { |record| crawl(record.send(method), *vector) }
      else
        crawl(item.send(method), *vector)
      end
    end
  end
end
