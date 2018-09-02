module ReactiveRecord
  # The base collection class works with relationships
  # method overrides for scoped collections
  module ScopedCollection
    [:filter?, :collector?, :joins_with?, :related_records_for].each do |method|
      define_method(method) { |*args| @scope_description.send method, *args }
    end

    def set_pre_sync_related_records(related_records, _record = nil)
      @pre_sync_related_records = nil
      ReactiveRecord::Base.catch_db_requests do
        @pre_sync_related_records = filter_records(related_records)
        live_scopes.each do |scope|
          scope.set_pre_sync_related_records(@pre_sync_related_records)
        end
      end if filter?
    end

    def sync_scopes(related_records, record, filtering = true)
      filtering =
        @pre_sync_related_records && filtering &&
        ReactiveRecord::Base.catch_db_requests do
          related_records = update_collection(related_records)
        end
      reload_from_db if !filtering && joins_with?(record)
      live_scopes.each { |scope| scope.sync_scopes(related_records, record, filtering) }
    ensure
      @pre_sync_related_records = nil
    end

    def update_collection(related_records)
      if collector?
        update_collector_scope(related_records)
      else
        related_records = filter_records(related_records)
        update_filter_scope(@pre_sync_related_records, related_records)
      end
    end

    def update_collector_scope(related_records)
      current = Set.new([*@collection])
      (related_records - @pre_sync_related_records).each { |r| current << r }
      (@pre_sync_related_records - related_records).each { |r| current.delete(r) }
      replace(filter_records(current))
      Set.new([*@collection])
    end

    def update_filter_scope(before, after)
      if (collection || !@count.nil?) && before != after
        if collection
          (after - before).each { |r| push r }
          (before - after).each { |r| delete r }
        else
          @count += (after - before).count
          @count -= (before - after).count
          notify_of_change self # TODO: remove self .... and retest
        end
      end
      after
    end
  end
end
