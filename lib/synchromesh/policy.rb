module Synchromesh

  class InternalClassPolicy

    def initialize(regulated_klass)
      @regulated_klass = regulated_klass
    end

    EXPOSED_METHODS = [:regulate_connection, :regulate_all_broadcasts, :regulate_broadcast, :auto_connect, :disable_auto_connect]

    def regulate_connection(*channels, &block)
      regulate(channels, block, ConnectionRegulation)
    end

    def regulate_all_broadcasts(*channels, &block)
      regulate(channels, block, ChannelBroadcastRegulation)
    end

    def regulate_broadcast(*regulated_classes, &block)
      regulate(regulated_classes, block, InstanceBroadcastRegulation)
    end

    def auto_connect(*channels, &block)
      regulate(channels, block, AutoConnect)
    end

    def disable_auto_connect(*channels)
      regulate(channels, :disabled, AutoConnect)
    end

    def regulate(channels, block, regulation_klass)
      raise "you must provide a block to the regulate_#{policy} method" unless block
      channels = [@regulated_klass] if channels.empty?
      channels.each do |channel|
        regulation_klass.new channel, block
      end
    end
  end

  class Regulation

    def self.blocks_to_channels
      @blocks_to_channels ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def self.channels_to_blocks
      @channels_to_blocks ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def self.channels
      @channels_to_blocks.keys
    end

    def self.wrap_policy(policy, block)
      policy_klass = block.binding.receiver
      wrapped_policy = policy_klass.new(nil, nil)
      wrapped_policy.synchromesh_internal_policy_object = policy
      wrapped_policy
    end

    def self.each_channel_with_wrapped_policy(policy)
      blocks_to_channels.each do |block, channels|
        wrapped_policy = wrap_policy(policy, block)
        channels.each { |channel| yield block, channel, wrapped_policy }
      end
    end

    def initialize(channel, block)
      channel = channel.name if channel.is_a?(Class) && channel.name
      self.class.blocks_to_channels[block] << channel
      self.class.channels_to_blocks[channel] << block
    end

  end

  class ConnectionRegulation < Regulation
    def self.connect(channel, acting_user, instance_id)
      channel = channel.name if channel.is_a?(Class) && channel.name
      instance_id = instance_id.to_i if instance_id =~ /^\d+$/
      regs = applicable_regulations(channel, instance_id)
      params = [acting_user, instance_id]
      failed = regs.detect do |regulation|
        !regulation.call *params.first(regulation.arity)
      end
      raise "connection failed" if regs.empty? || failed
      true
    end

    def self.applicable_regulations(channel, instance_id)
      channel = channel.name if channel.is_a?(Class) && channel.name
      channel_regs = channels_to_blocks[channel].select { |proc| proc.parameters.count < 2 }
      if instance_id || channel_regs.count == 0
        channels_to_blocks[channel].select { |proc| proc.parameters.count == 2 }
      else
        channel_regs
      end
    end
  end

  class AutoConnect < Regulation
    def self.channels(acting_user)
      channels = []
      ConnectionRegulation.channels.each do |channel|
        next if disabled? channel
        channels << channel if accepts?(channel, acting_user)
        id = get_id(channel, acting_user)
        channels << [channel, id] if id && accepts?(channel, acting_user, id)
      end
      channels
    end

    def self.disabled?(channel)
      blocks_to_channels[:disabled].include? channel
    end

    def self.accepts?(channel, acting_user, instance_id = nil)
      ConnectionRegulation.connect(channel, acting_user, instance_id)
    rescue
      nil
    end

    def self.get_id(channel, acting_user)
      override = channels_to_blocks[channel].last
      if override
        override.call acting_user
      elsif acting_user
        acting_user.id
      end
    rescue
      nil
    end

  end


  class ChannelBroadcastRegulation < Regulation
    def self.broadcast(policy)
      each_channel_with_wrapped_policy(policy) do |regulation, channel, wrapped_policy|
        regulation.call wrapped_policy
        policy.send_unassigned_sets_to channel
      end
    end
  end

  class InstanceBroadcastRegulation < Regulation
    def self.broadcast(instance, policy)
      channels_to_blocks[instance.class.name].each do |regulation|
        instance.instance_exec wrap_policy(policy, regulation), &regulation
      end
    end
  end

  class InternalPolicy

    EXPOSED_METHODS = [:send_all, :send_all_but, :send_only, :obj]

    def send_all
      SendSet.new(self)
    end

    def send_all_but(*execeptions)
      SendSet.new(self, exclude: execeptions)
    end

    def send_only(*white_list)
      SendSet.new(self, white_list: white_list)
    end

    def obj
      @obj
    end

    def self.regulate_connection(acting_user, channel_string)
      channel = channel_string.split("-")
      channel_klass = channel[0]
      id = channel[1]
      ConnectionRegulation.connect(channel_klass, acting_user, id)
    end

    def self.regulate_broadcast(model, &block)
      internal_policy = InternalPolicy.new(model, model.attributes)
      ChannelBroadcastRegulation.broadcast(internal_policy)
      InstanceBroadcastRegulation.broadcast(model, internal_policy)
      internal_policy.broadcast &block
    end

    def initialize(obj, attributes)
      @obj = obj
      @attributes = attributes.map(&:to_sym).to_set
      @unassigned_send_sets = []
      @channel_sets = Hash.new { |hash, key| hash[key] = @attributes }
    end

    def id
      @id ||= "#{self.object_id}-#{Time.now.to_f}"
    end

    def send_unassigned_sets_to(channel)
      unless @unassigned_send_sets.empty?
        @channel_sets[channel] = @unassigned_send_sets.inject(@channel_sets[channel]) do |set, send_set|
          send_set.merge(set)
        end
        @unassigned_send_sets = []
      end
    end

    def add_unassigned_send_set(send_set)
      @unassigned_send_sets << send_set
    end

    def send_set_to(send_set, channels)
      channels.flatten(1).each do |channel|
        merge_set(send_set, channel)
        @unassigned_send_sets.delete(send_set)
      end
    end

    def merge_set(send_set, channel)
      return unless channel
      channel = channel.name if channel.is_a?(Class) && channel.name
      @channel_sets[channel] = send_set.merge(@channel_sets[channel])
    end

    def channel_list
      @channel_sets.collect { |channel, _value| channel_to_string channel }
    end

    def channel_to_string(channel)
      if channel.is_a? String
        channel
      else
        "#{channel.class.name}-#{channel.id}"
      end
    end

    def filter(h, attribute_set)
      r = {}
      h.each { |key, value| r[key.to_sym] = value if attribute_set.member? key.to_sym}
      r
    end

    def send_message(header, channel, attribute_set, &block)
      record = filter(@obj.react_serializer, attribute_set)
      previous_changes = filter(@obj.previous_changes, attribute_set)
      return if record.empty? && previous_changes.empty?
      yield(
        header.merge(
          channel: channel_to_string(channel),
          record: record,
          previous_changes: previous_changes
        )
      )
    end

    def broadcast(&block)
      header = {broadcast_id: id, channels: channel_list, klass: @obj.class.name}
      @channel_sets.each do |channel, attribute_set|
        send_message header, channel, attribute_set, &block
      end
    end
  end

  class SendSet

    def to(*channels)
      @policy.send_set_to(self, channels)
    end

    def initialize(policy, exclude: nil, white_list: nil)
      @policy = policy
      @policy.add_unassigned_send_set(self)
      @excluded = exclude.map &:to_sym if exclude
      @white_list = white_list.map &:to_sym if white_list
    end

    def merge(set)
      set = set.difference(@excluded) if @excluded
      set = set.intersection(@white_list) if @white_list
      set
    end

  end

  module ClassPolicyMethods
    def synchromesh_internal_policy_object
      @synchromesh_internal_policy_object ||= InternalClassPolicy.new(name || self)
    end
    InternalClassPolicy::EXPOSED_METHODS.each do |policy_method|
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
    InternalPolicy::EXPOSED_METHODS.each do |method|
      define_method method do |*args, &block|
        synchromesh_internal_policy_object.send method, *args, &block
      end unless respond_to? method
    end
    define_method :initialize do |*args|
    end unless instance_methods(false).include?(:initialize)
  end
end

class Class
  Synchromesh::ClassPolicyMethods.instance_methods.each do |method|
    define_method method do |*args, &block|
      if name =~ /Policy$/
        @synchromesh_internal_policy_object = Synchromesh::InternalClassPolicy.new(name.gsub(/Policy$/,""))
        include Synchromesh::PolicyMethods
        send method, *args, &block
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
