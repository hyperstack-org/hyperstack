require 'syncromesh/configuration'
load './active_record/base'

module Syncromesh

  extend Syncromesh::Configuration

  define_setting :transport, :pusher
  define_setting :app_id
  define_setting :key
  define_setting :secret
  define_setting :encrypted, true
  define_setting :channel_prefix, :syncromesh
  define_setting :seconds_polled_data_will_be_retained, 5*60
  define_setting :seconds_between_poll, 0.50
  define_setting :client_logging, true

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
    puts "********************* after_change(#{model}) transport = #{transport}"
    if transport == :pusher
      pusher.trigger(Syncromesh.channel, 'change', klass: model.class.name, record: model.react_serializer)
    elsif transport == :simple_poller
      SimplePoller.write('change', {klass: model.class.name, record: model.react_serializer})
    elsif transport != :none
      raise "Unknown transport #{Syncromesh.transport} - not supported"
    end
  end

  def self.after_destroy(model)
    puts "********************** after_destroy(#{model}) transport = #{transport}"
    if transport == :pusher
      pusher.trigger(Syncromesh.channel, 'destroy', klass: model.class.name, record: model.react_serializer)
    elsif transport == :simple_poller
      SimplePoller.write('destroy', {klass: model.class.name, record: model.react_serializer})
    elsif transport != :none
      raise "Unknown transport #{Syncromesh.transport} - not supported"
    end
  end
end

# module ActiveRecord
#   class Base
#
#     puts "&&&&&&&&&&&&&&&&&&&& updating active record base &&&&&&&&&&&&&&&&&&&&&&&&"
#
#     class << self
#
#       def no_auto_sync
#         @no_auto_sync = true
#       end
#
#       alias_method :old_scope, :scope
#
#       def scope(name, server, client = nil)
#         puts "********************AR BASE NOW scoping #{name} with #{server}"
#         if server == :no_sync
#           server = client
#           client = nil
#         elsif client.nil? && @no_auto_sync.nil?
#           client = server
#         end
#         if RUBY_ENGINE == 'opal' && client
#           to_sync name do |scope, model|
#             puts "to_sync #{name}"
#             if ReactiveRecord::SyncWrapper.new(model).instance_eval(&client)
#               scope << model
#             else
#               scope.delete(model)
#             end
#           end
#         end
#         old_scope(name, server)
#       end
#     end
#
#     if RUBY_ENGINE != 'opal'
#
#       after_commit :syncromesh_after_change, on: [:create, :update]
#       after_commit :syncromesh_after_destroy, on: [:destroy]
#
#       def syncromesh_after_change
#         puts "**********************after_change callback"
#         Syncromesh.after_change self
#       end
#
#       def syncromesh_after_destroy
#         puts "***********************after_destroy callback"
#         Syncromesh.after_destroy self
#       end
#
#     end
#
#   end
# end
