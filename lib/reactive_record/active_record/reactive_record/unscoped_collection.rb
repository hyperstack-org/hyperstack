module ReactiveRecord
  # The base collection class works with relationships
  # method overrides for the unscoped collection
  module UnscopedCollection
    def set_pre_sync_related_records(related_records, _record = nil)
      @pre_sync_related_records = related_records
      live_scopes.each { |scope| scope.set_pre_sync_related_records(@pre_sync_related_records) }
    end

    def sync_scopes(related_records, record, filtering = true)
      live_scopes.each { |scope| scope.sync_scopes(related_records, record, filtering) }
    ensure
      @pre_sync_related_records = nil
    end
  end
end
