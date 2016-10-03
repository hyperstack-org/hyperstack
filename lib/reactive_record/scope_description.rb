module ReactiveRecord
  # Keeps track of the details (client side) of a scope.
  # The main point is to provide knowledge of what models
  # the scope is joined with, and the client side
  # filter (sync) proc
  class ScopeDescription

    def self.all
      @all ||= Hash.new { |h, k| h[k] = Hash.new }
    end

    def initialize(model, name, opts)
      ScopeDescription.all[model][name] = self
      @filter_proc = filter_proc(opts)
      @name = name
      @model = model
      build_joins opts[:joins]
    end

    def filter_proc(opts)
      return true unless opts.key?(:client)
      client_opt = opts[:client]
      return client_opt if !client_opt || client_opt.respond_to?(:call)
      raise 'Scope option :sync must be a proc, false, or nil'
    end

    def build_joins(joins_list)
      if !@filter_proc
        @joins = { all: [] }
      elsif joins_list.nil?
        @joins = { @model => [[]], all: [] }
      elsif joins_list == :all
        @joins = { all: [[]] }
      elsif joins_list.is_a?(Array)
        @joins = {}
        joins_list.each(&:map_joins_path)
      else
        @joins = {}
        map_joins_path(joins_list)
      end
    end

    def map_joins_path(path)
      vector = []
      joined_model = path.split('.').inject(@model) do |model, attribute|
        association = model.reflect_on_association(attribute)
        raise build_error(path, model, attribute) unless association
        vector = [association.inverse_of] + vector
        association.klass
      end
      @joins[joined_model] ||= []
      @joins[joined_model] << vector
    end

    def build_error(path, model, attribute)
      "Could not find joins association '#{model.name}.#{attribute}' "\
      "for '#{path}' while processing scope #{@model.name}.#{@name}."
    end

    def related_records_for(record)
      ReactiveRecord::Base.catch_db_requests do
        (@joins[record.class.base_class] || @joins[:all]).inject([]) do |requests, vector|
          requests + [*vector.inject(record) { |a, e| a.send(e) }]
        end
      end
    end

    def joins_with?(record)
      @joins.detect do |klass, _vector|
        klass != :all && (record.class == klass || record.class < klass)
      end
    end

    def filter?
      @filter_proc.respond_to?(:call)
    end

    def collector?
      filter? && @filter_proc.arity == 1
    end

    def filter_records(related_records)
      puts "filter_records(#{related_records.to_a}, #{related_records.count})"
      if collector?
        Set.new(@filter_proc.call(related_records))
      else
        Set.new(related_records.select { |r| puts "filtering #{r} is nil? #{r.nil?}"; r.instance_eval &@filter_proc })
      end.tap { |x| puts "returning #{x} from filter_records"}
    end
  end
end
