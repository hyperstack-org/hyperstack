module ActiveRecord
  class Base

    class << self

      def no_auto_sync
        @no_auto_sync = true
      end

      alias_method :old_scope, :scope

      def scope(name, server, client = nil)
        if server == :no_sync
          server = client
          client = nil
        elsif client.nil? && @no_auto_sync.nil?
          client = server
        end
        if RUBY_ENGINE == 'opal' && client
          to_sync name do |scope, model|
            if ReactiveRecord::SyncWrapper.new(model).instance_eval(&client)
              scope << model
            else
              scope.delete(model)
            end
          end
        end
        old_scope(name, server)
      end
    end
  end
end

if RUBY_ENGINE == 'opal'

  require_relative 'syncromesh/version'
  require_relative 'reactive_record/syncromesh'
  require_relative 'reactive_record/base'
  require_relative 'reactive_record/sync_wrapper'

else

  require 'opal'
  require "syncromesh/version"
  require "syncromesh/configuration"

  module Syncromesh

    extend Syncromesh::Configuration

    define_setting :transport, :pusher
    define_setting :app_id
    define_setting :key
    define_setting :secret
    define_setting :encrypted, true
    define_setting :channel_prefix
    define_setting :seconds_polled_data_will_be_retained, 5*60
    define_setting :seconds_between_poll, 0.50
    define_setting :client_logging, true

    def self.pusher
      unless channel_prefix
        transport = nil
        raise "******** NO CHANNEL PREFIX SET ***************"
      end
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
      elsif transport == :simple_poller
        SimplePoller.write('change', {klass: model.class.name, record: model.react_serializer})
      elsif transport != :none
        raise "Unknown transport #{Syncromesh.transport} - not supported"
      end
    end

    def self.after_destroy(model)
      if transport == :pusher
        pusher.trigger(Syncromesh.channel, 'destroy', klass: model.class.name, record: model.react_serializer)
      elsif transport == :simple_poller
        SimplePoller.write('destroy', {klass: model.class.name, record: model.react_serializer})
      elsif transport != :none
        raise "Unknown transport #{Syncromesh.transport} - not supported"
      end
    end

    module SimplePoller

      require "pstore"

      def self.subscribe
        subscriber = SecureRandom.hex(10)
        update_store do |store|
          store[subscriber] = {data: [], last_read_at: Time.now}
        end
        subscriber
      end

      def self.read(subscriber)
        update_store do |store|
          data = store[subscriber][:data] rescue []
          store[subscriber] = {data: [], last_read_at: Time.now}
          data
        end
      end

      def self.write(event, data)
        update_store do |store|
          store.each do |subscriber, subscriber_store|
            subscriber_store[:data] << [event, data]
          end
        end

      end

      def self.update_store
        store = PStore.new('syncromesh-simple-poller-store')
        store.transaction do
          data = store[:data] || {}
          data.delete_if do |subscriber, subscriber_store|
            subscriber_store[:last_read_at] < Time.now-Syncromesh.seconds_polled_data_will_be_retained
          end
          result = yield data
          store[:data] = data
          result
        end
      end
    end
  end

  module ActiveRecord

    class Base
      after_commit :syncromesh_after_change, on: [:create, :update]
      after_commit :syncromesh_after_destroy, on: [:destroy]

      def syncromesh_after_change
        Syncromesh.after_change self
      end

      def syncromesh_after_destroy
        Syncromesh.after_destroy self
      end
    end

  end

  module ReactiveRecord

    class SyncromeshController < ::ActionController::Base

      def subscribe
        render json: {id: Syncromesh::SimplePoller.subscribe}
      end

      def read
        render json: Syncromesh::SimplePoller.read(params[:subscriber])
      end
    end

  end

  Opal.append_path File.expand_path('../', __FILE__).untaint

end
