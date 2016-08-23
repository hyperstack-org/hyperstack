module Synchromesh

  class InternalClassPolicy

    def initialize(regulated_klass)
      @regulated_klass = regulated_klass
    end

    def regulate_connection(*channels, &block)
      regulate(:connection, channels, block, ChannelRegulation)
    end

    def regulate_all_broadcasts(*channels, &block)
      regulate(:all_broadcasts, channels, block, ChannelBroadcastRegulation)
    end

    def regulate_broadcast(*regulated_classes, &block)
      regulate(:broadcast, regulated_classes, block, InstanceBroadcastRegulation)
    end

    def regulate(policy, channels, regulation_klass, &block)
      raise "you must provide a block to the regulate_#{policy} method" unless block
      channels = [@regulated_klass] if channels.empty?
      channels.each do |channel|
        regulation_klass.new channel, block
      end
    end
  end

  class Regulation
    def self.regulations
      @regulations ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def initialize(channel, block)
      self.class.regulations[channel] << block
    end
  end

  class ChannelRegulation < Regulation
    def self.connect(channel, *params)
      connected = regulation[channel].inject(false) do |found, regulation|
        if params.count == 2 && regulation.params.count != 2
          found
        elsif regulation.call *params.first(regulation.params.count)
          true
        else
          break
        end
      end
      raise "connection failed" unless connected
    end
  end

  class ChannelBroadcastRegulation < Regulation
    def self.broadcast(channel, policy)
      regulations[channel].each do |regulation|
        regulation.call regulation
      end
      policy.send_unassigned_sets_to channel
    end
  end

  class InstanceBroadcastRegulation < Regulation
    def self.broadcast(instance, policy)
      regulations[instance.class].each do |regulation|
        instance.instance_exec regulation, policy
      end
    end
  end

  class InternalPolicy

    def expose_send_all
      SendSet.new(self)
    end

    def expose_send_all_but(*execeptions)
      SendSet.new(self, exclude: execeptions)
    end

    def expose_send_only(*white_list)
      SendSet.new(self, white_list: white_list)
    end

    def expose_obj
      @object
    end

    def self.regulate_connection(active_user, channel_string)
      channel = channel_string.split("-")
      channel_klass = Object.const_get channel[0]
      id = channel[1]
      ChannelRegulation.connect(channel_klass, active_user, id)
    end

    def self.regulate_broadcast(model, &block)
      internal_policy = InternalPolicy.new(model, model.atttributes)
      Connections.class_channels.each do |channel|
        ChannelBroadcastRegulation.broadcast(channel, internal_policy)
      end
      InstanceBroadcastRegulation(model, internal_policy)
      internal_policy.broadcast &block
    end

    def initialize(obj, attributes)
      @obj = obj
      @attributes = attributes.to_set
      @unassigned_send_sets = []
      @channel_sets = {}
    end

    def id
      @id ||= "#{self.object_id}-#{Time.now.to_f}"
    end

    def send_unassigned_sets_to(channel)
      channels_sets[channel] = @unassigned_send_sets.inject(@attributes) do |set, send_set|
        send_set.merge(set)
      end unless @unassigned_send_sets.empty?
    end

    def add_unassigned_send_set(send_set)
      @unassigned_send_sets << send_set
    end

    def send_set_to(send_set, channels)
      @unassigned_send_sets.delete(send_set)
      channels.flatten(1).each { |channel| merge_set(channel, send_set) }
    end

    def merge_set(send_set, channel)
      return unless channel
      channel = [channel.class, channel.id] unless channel.kind_of? Class
      channels_sets[channel] = send_set.merge(@channel_sets[channel] || @unassigned_send_sets)
    end

    def channel_list
      @channel_sets.collect { |channel, _value| channel_to_string channel }
    end

    def channel_to_string(channel)
      if channel.is_a? Class
        channel.name
      else
        "#{channel.class.name}-#{channel.id}"
      end
    end

    def filter(h, attribute_set)
      h.delete_if { |key, _value| !attribute_set.member? key}
    end

    def broadcast(&block)
      channels = channel_list
      @channel_sets.each do |channel, attribute_set|
        block.call(
          broadcast_id: id,
          channel: channel_to_string(channel),
          channels: channels,
          klass: model.class.name,
          record: filter(model.react_serializer, attribute_set),
          previous_changes: filter(model.previous_changes, attribute_set)
        )
      end
    end

  end

  class SendSet

    def to(*channels)
      @policy.send_set_to(channels)
    end

    def initialize(policy, exclude: nil, white_list: nil)
      @policy = policy
      @policy.add_unassigned_send_set(self)
      @excluded = exclude
      @white_list = white_list
    end

    def merge(set)
      set = set.difference(@excluded) if @excluded
      set = set.intersection(@white_list) if @white_list
      set
    end

  end

  module ClassPolicyMethods
    def synchromesh_internal_policy_object
      @synchromesh_internal_policy_object ||= InternalClassPolicy.new(self)
    end
    InternalClassPolicy.instance_methods.grep(/^regulate/).each do |policy_method|
      define_method policy_method do |*klasses, &block|
        synchromesh_internal_policy_object.send policy_method, *klasses, &block
      end unless respond_to? policy_method
    end
  end

  module PolicyMethods
    def self.included(base)
      base.class_eval do
        extend ClassPolicyMethods
      end
    end
    attr_accessor :synchromesh_internal_policy_object
    InternalPolicy.instance_methods.grep(/^expose_/).each do |exposed_method|
      method = exposed_method.gsub(/^expose_/,'')
      define_method method do |*args, &block|
        synchromesh_internal_policy_object.send exposed_method, *args, &block
      end unless respond_to? method
    end
  end
end

class Class
  Synchromesh::ClassPolicyMethods.instance_methods.each do |method|
    define_method method do |*args, &block|
      if self.name =~ /Policy$/
        self.include Synchromesh::PolicyMethods
        self.send method, *args, &block
      else
        class << self
          Synchromesh::ClassPolicyMethods.instance_methods.each do |method|
            undef_method method
          end
        end
        method_missing(method, *args, &block)
      end
    end unless respond_to? method
  end
end
