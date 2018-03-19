module ReactiveRecord
  class Broadcast

    def self.after_commit(operation, model)
      Hyperloop::InternalPolicy.regulate_broadcast(model) do |data|
        if !Hyperloop.on_server? && Hyperloop::Connection.root_path
          send_to_server(operation, data)
        else
          SendPacket.run(data, operation: operation)
        end
      end
    rescue ActiveRecord::StatementInvalid => e
      raise e unless e.message == "Could not find table 'hyperloop_connections'"
    end unless RUBY_ENGINE == 'opal'

    def self.send_to_server(operation, data)
      salt = SecureRandom.hex
      authorization = Hyperloop.authorization(salt, data[:channel], data[:broadcast_id])
      raise 'no server running' unless Hyperloop::Connection.root_path
      SendPacket.remote(
        Hyperloop::Connection.root_path,
        data,
        operation: operation,
        salt: salt,
        authorization: authorization
      )
    end unless RUBY_ENGINE == 'opal'

    class SendPacket < Hyperloop::ServerOp
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
          Hyperloop.authorization(
            params.salt, params.channel, params.broadcast_id
          ) == params.authorization
        end
        dispatch_to { params.channel }
      end
    end

    SendPacket.on_dispatch do |params|
      in_transit[params.broadcast_id].receive(params) do |broadcast|
        if params.operation == :destroy
          ReactiveRecord::Collection.sync_scopes broadcast
        else
          ReactiveRecord::Base.when_not_saving(broadcast.klass) do
            ReactiveRecord::Collection.sync_scopes broadcast
          end
        end
      end
    end

    def self.to_self(record, data = {})
      # simulate incoming packet after a local save
      operation = if record.new?
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
        backing_record = @backing_record || klass.find(record[:id]).backing_record
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
      @record.merge!(id: record.id) if record.id
      record.backing_record.destroyed = @destroyed
      @backing_record = record.backing_record
      attributes = record.attributes
      data.each do |k, v|
        next if klass.reflect_on_association(k) || attributes[k] == v
        @previous_changes[k] = [attributes[k], v]
      end
      self
    end

    def receive(params)
      @destroyed = params.operation == :destroy
      @is_new = params.operation == :create
      @channels ||= Hyperloop::IncomingBroadcast.open_channels.intersection params.channels
      #raise 'synchromesh security violation' unless @channels.include? params.channels
      @received << params.channel
      @klass ||= params.klass
      @record.merge! params.record
      @previous_changes.merge! params.previous_changes
      @backing_record = ReactiveRecord::Base.exists?(klass, params.record[:id])
      yield complete! if @channels == @received
    end

    def complete!
      self.class.in_transit.delete @id
    end

    def merge_current_values(br)
      current_values = Hash[*@previous_changes.collect do |attr, values|
        value = attr == :id ? record[:id] : values.first
        if br.attributes.key?(attr) &&
           br.attributes[attr] != br.convert(attr, value) &&
           br.attributes[attr] != br.convert(attr, values.last)
          puts "warning #{attr} has changed locally - will force a reload.\n"\
               "local value: #{br.attributes[attr]} remote value: #{br.convert(attr, value)}->#{br.convert(attr, values.last)}"
          return nil
        end
        [attr, value]
      end.compact.flatten].merge(br.attributes)
      klass._react_param_conversion(current_values)
    end
  end
end
