require 'synchromesh/configuration'
# Provides the configuration and the two basic routines for the server
# to indicate that records have changed: after_change and after_destroy
module Synchromesh
  extend Configuration

  def self.config_reset
    @pusher = nil
  end

  define_setting :transport, :none
  define_setting :opts, {}
  define_setting :channel_prefix
  define_setting :client_logging, true

  def self.app_id
    opts[:app_id] || Pusher.app_id if transport == :pusher
  end

  def self.key
    opts[:key] || Pusher.key if transport == :pusher
  end

  def self.secret
    opts[:secret] || Pusher.secret if transport == :pusher
  end

  def self.encrypted
    opts.key?(:encrypted) ? opts[:encrypted] : true
  end

  def self.seconds_polled_data_will_be_retained
    opts[:seconds_polled_data_will_be_retained] || (5 * 60)
  end

  def self.seconds_between_poll
    opts[:seconds_between_poll] || 0.5
  end

  def self.pusher
    unless @pusher
      unless channel_prefix
        self.transport = nil
        raise '******** NO CHANNEL PREFIX SET ***************'
      end
      @pusher = Pusher::Client.new(
        opts || { app_id: app_id, key: key, secret: secret }
      )
    end
    @pusher
  end

  def self.channel
    channel_prefix.to_s
  end

  def self.after_change(model)
    run_policies('change', model)
    #send_to_transport('change', model)
  end

  def self.after_destroy(model)
    run_policies('destroy', model)
    #send_to_transport('destroy', model)
  end

  def self.filter(h, attribute_set)
    h.delete_if { |key, _value| !attribute_set.member? key}
  end

  def self.filter_previous_changes(model, attribute_set)
    model.previous_changes

  def self.send_to_transport(channel, channels, message, model, attribute_set)
    data_hash = {
      channel: channel,
      channels: channels,
      klass: model.class.name,
      record: filter(model.react_serializer, attribute_set),
      previous_changes: filter(model.previous_changes, attribute_set)
    }
    case transport
    when :pusher
      pusher.trigger(Synchromesh.channel, message, data_hash)
    when :simple_poller
      SimplePoller.write(channel, message, data_hash)
    else
      transport_error
    end
  end

  def self.transport_error
    unless transport == :none
      raise "Unknown transport #{Synchromesh.transport} - not supported"
    end
  end
end
