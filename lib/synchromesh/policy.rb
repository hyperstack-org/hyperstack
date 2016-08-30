module Synchromesh

  class InternalClassPolicy

    def initialize(regulated_klass)
      @regulated_klass = regulated_klass
    end

    EXPOSED_METHODS = [
      :regulate_class_connection, :always_allow_connection, :regulate_instance_connections,
      :regulate_all_broadcasts, :regulate_broadcast
    ]

    def regulate_class_connection(*args, &block)
      regulate(ClassConnectionRegulation, args, &block)
    end

    def always_allow_connection(*args)
      regulate(ClassConnectionRegulation, args) { true }
    end

    def regulate_instance_connections(*args, &block)
      regulate(InstanceConnectionRegulation, args, &block)
    end

    def regulate_all_broadcasts(*args, &block)
      regulate(ChannelBroadcastRegulation, args, &block)
    end

    def regulate_broadcast(*args, &block)
      regulate(InstanceBroadcastRegulation, args, &block)
    end

    def regulate(regulation_klass, args, &block)
      raise "you must provide a block to the regulate_#{policy} method" unless block
      if args.last.is_a? Hash
        opts = args.last
        args = args[0..-2]
      else
        opts = {}
      end
      args = [@regulated_klass] if args.empty?
      args.each do |regulated_klass|
        regulation_klass.add_regulation regulated_klass, opts, &block
      end
    end
  end

  class Regulation

    class << self

      def add_regulation(channel, opts={}, &block)
        channel = channels[channel]
        channel.opts.merge! opts
        channel.blocks << block
        channel
      end

      def channels
        @channels ||= Hash.new do |hash, channel|
          if channel.is_a? String
            hash[channel] = new(channel)
          elsif channel.is_a?(Class) && channel.name
            hash[channel.name]
          else
            hash[channel.class.name]
          end
        end
      end

      def wrap_policy(policy, block)
        policy_klass = block.binding.receiver
        wrapped_policy = policy_klass.new(nil, nil)
        wrapped_policy.synchromesh_internal_policy_object = policy
        wrapped_policy
      end

    end

    attr_reader :klass

    def opts
      @opts ||= {}
    end

    def blocks
      @blocks ||= []
    end

    def regulate_for(acting_user)
      @regulator ||= Enumerator.new do |y|
        blocks.each do |block|
          y << acting_user.instance_eval(&block)
        end
      end
    end

    def initialize(klass)
      @klass = klass
    end

  end

  class ClassConnectionRegulation < Regulation

    def connectable?(acting_user)
      connected = regulate_for(acting_user).all? unless blocks.empty?
    ensure
      connected
    end

    def self.connect(klass, acting_user)
      raise "connection failed" unless channels[klass].connectable?(acting_user)
    end

    def self.auto_connections(acting_user)
      channels.collect do |name, channel|
        name unless channel.auto_connect_disabled? || !channel.connectable?(acting_user)
      end.compact
    end

    def auto_connect_disabled?
      opts.has_key?(:auto_connect) && !opts[:auto_connect]
    end

  end

  class InstanceConnectionRegulation < Regulation

    def connectable_to(acting_user)
      regulate_for(acting_user).entries.compact.flatten(1)
    rescue Exception
      []
    end

    def self.connect(instance, acting_user)
      unless channels[instance].connectable_to(acting_user).include? instance
        raise "connection failed"
      end
    end

    def self.auto_connections(acting_user)
      channels.collect do |connections, channel|
        channel.connectable_to(acting_user).collect do |obj|
          [obj.class.name, obj.id]
        end
      end.flatten(1)
    end
  end

  class ChannelBroadcastRegulation < Regulation
    class << self
      def add_regulation(channel, opts={}, &block)
        blocks_to_channels[block] << super
      end

      def broadcast(policy)
        each_channel_with_wrapped_policy(policy) do |regulation, channel, wrapped_policy|
          regulation.call wrapped_policy
          policy.send_unassigned_sets_to channel.klass
        end
      end

      def each_channel_with_wrapped_policy(policy)
        blocks_to_channels.each do |block, channels|
          wrapped_policy = wrap_policy(policy, block)
          channels.each { |channel| yield block, channel, wrapped_policy }
        end
      end

      def blocks_to_channels
        @blocks_to_channels ||= Hash.new { |hash, key| hash[key] = [] }
      end
    end
  end

  class InstanceBroadcastRegulation < Regulation
    def self.broadcast(instance, policy)
      channels[instance].blocks.each do |regulation|
        instance.instance_exec wrap_policy(policy, regulation), &regulation
      end
    end
  end

  module AutoConnect
    def self.channels(acting_user)
      ClassConnectionRegulation.auto_connections(acting_user) +
      InstanceConnectionRegulation.auto_connections(acting_user)
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
      id = channel[1]
      if channel.length == 2
        object = Object.const_get(channel[0]).find(channel[1])
        InstanceConnectionRegulation.connect(object, acting_user)
      else
        ClassConnectionRegulation.connect(channel[0], acting_user)
      end
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
