if RUBY_ENGINE == 'opal'

  require_relative 'syncromesh/version'

  module ReactiveRecord

    class Syncromesh

      include React::IsomorphicHelpers

      before_first_mount do |context|
        if on_opal_client?

          puts "BEFORE FIRST MOUNT"

          change = lambda do |data|
            data = Hash.new(data)
            Base.when_not_saving(Object.const_get(data[:klass])) do |klass|
              puts "changing record #{data}"
              klass._react_param_conversion(data[:record]).backing_record.sync_scopes
            end
          end

          destroy = lambda do |data|
            data = Hash.new(data)
            puts "destroying record #{data}"
            record = Object.const_get(data[:klass])._react_param_conversion(data[:record])
            ReactiveRecord::Base.load_data { record.destroy }
            record.backing_record.destroyed = true
            record.backing_record.sync_scopes
          end

          %x{
            Pusher.log = function(message) {
              if (window.console && window.console.log) {
                window.console.log(message);
              }
            };

            var pusher = new Pusher('dc9c8b9188641559cfd9', {
              encrypted: true
            });

            var channel = pusher.subscribe('syncromesh');
            channel.bind('change', change);

            var channel = pusher.subscribe('syncromesh');
            channel.bind('destroy', destroy);
          }
        end
      end
    end

    class Base

      def self.when_not_saving(model)
        if @records[model].detect { |record| record.saving? }
          poller = every (0.1) do
            unless @records[model].detect { |record| record.saving? }
              poller.stop
              yield model
            end
          end
        else
          yield model
        end
      end

    end

  end

else

  require "syncromesh/version"
  require 'helpers/configuration'
  require 'opal'

  module Syncromesh

    extend Syncromesh::Configuration

    define_setting :transport, :pusher
    define_setting :app_id
    define_setting :key
    define_setting :secret
    define_setting :encrypted, true
    define_setting :channel_prefix, :syncromesh

    def self.pusher
      @pusher ||= Pusher::Client.new(
        app_id: app_id,
        key: key,
        secret: secret,
        encrypted: encrypted
      )
    end

    def self.channel
      "#{channel_prefix}"
    end

    def self.after_change(model)
      if transport == :pusher
        pusher.trigger(Syncromesh.channel, 'change', klass: model.class.name, record: model.react_serializer)
      else
        raise "Unknown transport #{Syncromesh.transport} - not supported"
      end
    end

    def self.after_destroy(model)
      if transport == :pusher
        pusher.trigger(Syncromesh.channel, 'destroy', klass: model.class.name, record: model.react_serializer)
      else
        raise "Unknown transport #{Syncromesh.transport} - not supported"
      end
    end

  end

  class ActiveRecord::Base

    after_commit :syncromesh_after_change, on: [:create, :update]
    after_commit :syncromesh_after_destroy, on: [:destroy]

    def syncromesh_after_change
      Syncromesh.after_change self
    end

    def syncromesh_after_destroy
      Syncromesh.after_destroy self
    end

  end

  Opal.append_path File.expand_path('../', __FILE__).untaint

end
