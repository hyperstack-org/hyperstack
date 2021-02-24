module ReactiveRecord
  class Broadcast

    def self.after_commit(operation, model)
      # Calling public_columns_hash once insures all policies are loaded
      # before the first broadcast.
      @public_columns_hash ||= ActiveRecord::Base.public_columns_hash
      Hyperstack::InternalPolicy.regulate_broadcast(model) do |data|
        puts "Broadcast aftercommit hook: #{data}" if Hyperstack::Connection.show_diagnostics

        if !Hyperstack.on_server? && Hyperstack::Connection.root_path
          send_to_server(operation, data) rescue nil # fails if server no longer running so ignore
        else
          SendPacket.run(data, operation: operation)
        end
      end
    rescue ActiveRecord::StatementInvalid => e
      raise e unless e.message == "Could not find table 'hyperstack_connections'"
    end unless RUBY_ENGINE == 'opal'

    def self.send_to_server(operation, data)
      salt = SecureRandom.hex
      authorization = Hyperstack.authorization(salt, data[:channel], data[:broadcast_id])
      raise 'no server running' unless Hyperstack::Connection.root_path
      Timeout::timeout(Hyperstack.send_to_server_timeout) do
        SendPacket.remote(
          Hyperstack::Connection.root_path,
          data,
          operation: operation,
          salt: salt,
          authorization: authorization
        ).tap { |p| raise p.error if p.rejected? }
      end
    rescue Timeout::Error
      puts "\n********* FAILED TO RECEIVE RESPONSE FROM SERVER WITHIN #{Hyperstack.send_to_server_timeout} SECONDS. CHANGES WILL NOT BE SYNCED ************\n"
      raise 'no server running'
    end unless RUBY_ENGINE == 'opal'

    class SendPacket < Hyperstack::ServerOp
      param authorization: nil, nils: true
      param salt: nil
      param :operation
      param :broadcast_id
      param :channel
      param :channels
      param :klass
      param :record
      param :operation
      param :previous_changes

      unless RUBY_ENGINE == 'opal'
        validate do
          params.authorization.nil? ||
          Hyperstack.authorization(
            params.salt, params.channel, params.broadcast_id
          ) == params.authorization
        end
        dispatch_to do
          # No need to broadcast if the changes are filtered out by a policy
          params.channel unless params.operation == :change && params.previous_changes.empty?
        end
      end
    end

    SendPacket.on_dispatch do |params|
      in_transit[params.broadcast_id].receive(params) do |broadcast|
        if params.operation == :destroy
          ReactiveRecord::Collection.sync_scopes broadcast
        else
          ReactiveRecord::Collection.sync_scopes broadcast.process_previous_changes
        end
      end
    end if RUBY_ENGINE == 'opal'

    def self.to_self(record, data = {})
      # simulate incoming packet after a local save
      operation = if record.new_record?
                    :create
                  elsif record.destroyed?
                    :destroy
                  else
                    :change
                  end
      dummy_broadcast = new.local(operation, record, data)
      record.backing_record.sync! data unless operation == :destroy
      ReactiveRecord::Collection.sync_scopes dummy_broadcast
    end

    def record_with_current_values
      ReactiveRecord::Base.load_data do
        backing_record = @backing_record || klass.find(record[klass.primary_key]).backing_record
        if destroyed?
          backing_record.ar_instance
        else
          merge_current_values(backing_record)
        end
      end
    end

    def record_with_new_values
      klass._react_param_conversion(record).tap do |ar_instance|
        if destroyed?
          ar_instance.backing_record.destroy_associations
        elsif new?
          ar_instance.backing_record.initialize_collections
        end
      end
    end

    def new?
      @is_new
    end

    def destroyed?
      @destroyed
    end

    def klass
      Object.const_get(@klass)
    end

    def to_s
      "klass: #{klass} record: #{record} new?: #{new?} destroyed?: #{destroyed?}"
    end

    # private

    attr_reader :record

    def self.open_channels
      @open_channels ||= Set.new
    end

    def self.in_transit
      @in_transit ||= Hash.new { |h, k| h[k] = new(k) }
    end

    def initialize(id)
      @id = id
      @received = Set.new
      @record = {}
      @previous_changes = {}
    end

    def local(operation, record, data)
      @destroyed = operation == :destroy
      @is_new = operation == :create
      @klass = record.class.name
      @record = data
      record.backing_record.destroyed = false
      @record[@klass.primary_key] = record.id if record.id
      record.backing_record.destroyed = @destroyed
      @backing_record = record.backing_record
      @previous_changes = record.changes
      self
    end

    def receive(params)
      @destroyed = params.operation == :destroy
      @channels ||= Hyperstack::IncomingBroadcast.open_channels.intersection params.channels
      @received << params.channel
      @klass ||= params.klass
      @record.merge! params.record
      @previous_changes.merge! params.previous_changes
      ReactiveRecord::Base.when_not_saving(klass) do
        @backing_record = ReactiveRecord::Base.exists?(klass, params.record[klass.primary_key])

        # first check to see if we already destroyed it and if so exit the block
        return if @backing_record&.destroyed

        # We ignore whether the record is being created or not, and just check and see if in our
        # local copy we have ever loaded this id before.  If we have then its not new to us.
        # BUT if we are destroying a record then it can't be treated as new regardless.
        # This is because we might be just doing a count on a scope and so no actual records will
        # exist.  Treating a destroyed record as "new" would cause us to first increment the
        # scope counter and then decrement for the destroy, resulting in a nop instead of a -1 on
        # the scope count.
        @is_new = !@backing_record&.id_loaded? && !@destroyed

        # it is possible that we are recieving data on a record for which we are also waiting
        # on an an inital data load in which case we have not yet set the loaded id, so we
        # set if now.
        @backing_record&.loaded_id = params.record[klass.primary_key]

        # once we have received all the data from all the channels (applies to create and update only)
        # we yield and process the record

        # pusher fake can send duplicate records which will result in a nil broadcast
        # so we also check that before yielding
        if @channels == @received && (broadcast = complete!)
          yield broadcast
        end
      end
    end

    def complete!
      self.class.in_transit.delete @id
    end

    def value_changed?(attr, value)
      attrs = @backing_record.synced_attributes
      return true if attr == @backing_record.primary_key
      return attrs[attr] != @backing_record.convert(attr, value) if attrs.key?(attr)

      assoc = klass.reflect_on_association_by_foreign_key attr

      return value unless assoc
      child = attrs[assoc.attribute]
      return value != child.id if child
      value
    end

    def integrity_check
      @previous_changes.each do |attr, value|
        next if @record.key?(attr) && @record[attr] == value.last
        Hyperstack::Component::IsomorphicHelpers.log "Broadcast contained change to #{attr} -> #{value.last} "\
                                     "without corresponding value in attributes (#{@record}).\n",
                                     :error
        raise "Broadcast Integrity Error"
      end
    end

    def process_previous_changes
      return self unless @backing_record
      integrity_check
      return self if destroyed?
      @record.dup.each do |attr, value|
        next if value_changed?(attr, value)
        @record.delete(attr)
        @previous_changes.delete(attr)
      end
      self
    end

    def merge_current_values(br)
      current_values = Hash[*@previous_changes.collect do |attr, values|
        value = attr == klass.primary_key ? record[klass.primary_key] : values.first
        if br.attributes.key?(attr) &&
           br.attributes[attr] != br.convert(attr, value) &&
           br.attributes[attr] != br.convert(attr, values.last)
          Hyperstack::Component::IsomorphicHelpers.log "warning #{attr} has changed locally - will force a reload.\n"\
               "local value: #{br.attributes[attr]} remote value: #{br.convert(attr, value)}->#{br.convert(attr, values.last)}",
               :warning
          return nil
        end
        [attr, value]
      end.compact.flatten(1)]
      klass._react_param_conversion(br.attributes.merge(current_values))
    end
  end
end
