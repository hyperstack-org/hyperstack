module Hyperstack

  class InternalClassPolicy

    def initialize(regulated_klass)
      unless regulated_klass.is_a?(Class)
        # attempt to constantize the class in case eager_loading in production
        # has loaded the policy before the class.  THis will insure that if
        # there is a class being regulated, it is loaded first.
        begin
          regulated_klass.constantize
        rescue NameError
          nil
        end
      end
      @regulated_klass = regulated_klass
    end

    attr_reader :regulated_klass

    EXPOSED_METHODS = [
      :regulate_class_connection, :always_allow_connection, :regulate_instance_connections,
      :regulate_all_broadcasts, :regulate_broadcast,
      :regulate_dispatches_from, :always_dispatch_from,
      :allow_change, :allow_create, :allow_read, :allow_update, :allow_destroy
    ]

    def regulate_class_connection(*args, &regulation)
      regulate(ClassConnectionRegulation, :class_connection, args, &regulation)
    end

    def always_allow_connection(*args)
      regulate(ClassConnectionRegulation, nil, args) { true }
    end

    def regulate_instance_connections(*args, &regulation)
      regulate(InstanceConnectionRegulation, :instance_connections, args, &regulation)
    end

    def regulate_all_broadcasts(*args, &regulation)
      regulate(ChannelBroadcastRegulation, :all_broadcasts, args, &regulation)
    end

    def regulate_broadcast(*args, &regulation)
      regulate(InstanceBroadcastRegulation, :broadcast, args, &regulation)
    end

    def regulate_dispatches_from(*args, &regulation)
      args.each do |klass|
        unless klass.respond_to? :dispatch_to
          raise 'you can only regulate_dispatches_from Operation classes'
        end
        klass._dispatch_to(self) { |sself| sself.regulated_klass if instance_eval(&regulation) }
      end
    end

    def always_dispatch_from(*args, &regulation)
      regulate_dispatches_from(*args) { true }
    end

    CHANGE_POLICIES = [:create, :update, :destroy]

    def self.allow_policy(policy, method)
      define_method "allow_#{policy}" do |*args, &regulation|
        process_args(policy, [], args, regulation) do |model|
          get_ar_model(model).class_eval { define_method("#{method}_permitted?", &regulation) }
        end
      end
    end

    CHANGE_POLICIES.each { |policy| allow_policy policy, policy }

    allow_policy(:read, :view)

    def allow_change(*args, &regulation)
      process_args('change', [:on], args, regulation) do |model, opts|
        model = get_ar_model(model)
        opts[:on] ||= CHANGE_POLICIES
        opts[:on].each do |policy|
          check_valid_on_option policy
          model.class_eval { define_method("#{policy}_permitted?", &regulation) }
        end
      end
    end

    def self.ar_base_descendants_map_cache
      @ar_base_descendants_map_cache ||= ActiveRecord::Base.descendants.map(&:name)
    end

    def get_ar_model(str)
      if str.is_a?(Class)
        unless str <= ActiveRecord::Base
          Hyperstack::InternalPolicy.raise_operation_access_violation(:non_ar_class, "#{str} is not a subclass of ActiveRecord::Base")
        end
        str
      else
        # we used to cache this here, but during eager loading the cache may get partially filled and never updated
        # so this guard will fail, now performance will be suckish, as this guard, required for security, takes some ms
        # def self.ar_base_descendants_map_cache
        #   @ar_base_descendants_map_cache ||= ActiveRecord::Base.descendants.map(&:name)
        # end
        # if Rails.env.production? && !Hyperstack::InternalClassPolicy.ar_base_descendants_map_cache.include?(str)
        if Rails.application.config.eager_load && !ActiveRecord::Base.descendants.map(&:name).include?(str)
          # AR::Base.descendants is eager loaded in production -> this guard works.
          # In development it may be empty or partially filled -> this guard may fail.
          # Thus guarded here only in production.
          Hyperstack::InternalPolicy.raise_operation_access_violation(:non_ar_class, "#{str} is either not defined or is not a subclass of ActiveRecord::Base")
        end
        Object.const_get(str)
      end
    end

    def self.regulated_klasses
      @regulated_klasses ||= Set.new
    end

    def regulate(regulation_klass, policy, args, &regulation)
      process_args(policy, regulation_klass.allowed_opts, args, regulation) do |regulated_klass, opts|
        self.class.regulated_klasses << regulated_klass.to_s
        regulation_klass.add_regulation regulated_klass, opts, &regulation
      end
    end

    def process_args(policy, allowed_opts, args, regulation)
      raise "you must provide a block to the regulate_#{policy} method" unless regulation
      *args, opts = args if args.last.is_a? Hash
      opts ||= {}
      args = process_to_opt(allowed_opts, opts, args)
      args.each do |regulated_klass|
        yield regulated_klass, opts
      end
    end

    def process_to_opt(allowed_opts, opts, args)
      opts.each do |opt, value|
        unless opt == :to || allowed_opts.include?(opt)
          raise "Unknown ':#{opt} => #{value}' option in policy definition"
        end
      end
      if (to = opts[:to])
        raise "option to: :#{to} is not recognized in allow_#{policy}" unless to == :all
        raise "option to: :all cannot be used with other classes" unless args.empty?
        [ActiveRecord::Base]
      elsif args.empty?
        [@regulated_klass]
      else
        args
      end
    end

    def check_valid_on_option(policy)
      unless CHANGE_POLICIES.include? policy
        valid_policies = CHANGE_POLICIES.collect { |s| ":{s}" }.to_sentence
        raise "only #{valid_policies} are allowed on the regulate_access :on option"
      end
    end

  end

  class Regulation

    class << self

      def add_regulation(klass, opts={}, &regulation)
        klass = regulations[klass]
        klass.opts.merge! opts
        klass.regulations << regulation
        klass
      end

      def regulations
        @regulations ||= Hash.new do |hash, klass|
          if klass.is_a? String
            hash[klass] = new(klass)
          elsif klass.is_a?(Class) && klass.name
            hash[klass.name]
          else
            hash[klass.class.name]
          end
        end
      end

      def wrap_policy(policy, regulation)
        begin
          policy_klass = regulation.binding.receiver
        rescue
          raise "Could not determine the class when regulating.  This is probably caused by doing something like &:send_all"
        end
        wrapped_policy = policy_klass.new(nil, nil)
        wrapped_policy.hyperstack_internal_policy_object = policy
        wrapped_policy
      end

      def allowed_opts
        []
      end

    end

    attr_reader :klass

    def opts
      @opts ||= {}
    end

    def regulations
      @regulations ||= []
    end

    def regulate_for(acting_user)
      Enumerator.new do |y|
        regulations.each do |regulation|
          y << acting_user.instance_eval(&regulation)
        end
      end
    end

    def auto_connect_disabled?
      opts.has_key?(:auto_connect) && !opts[:auto_connect]
    end

    def initialize(klass)
      @klass = klass
    end

  end

  class ClassConnectionRegulation < Regulation

    def self.add_regulation(klass, opts={}, &regulation)
      actual_klass = if klass.is_a?(Class)
                       klass
                     else
                       begin
                         klass.constantize
                       rescue NameError
                         nil
                       end
                     end
      if actual_klass && actual_klass.respond_to?(:dispatch_to)
        begin
          actual_klass.dispatch_to(actual_klass)
        rescue NoMethodError
          # this is the case for ClassPolicy where the instance method :dispatch_to has been deleted.
          nil
        end
      end
      super
    end

    def connectable?(acting_user)
      regulate_for(acting_user).all? unless regulations.empty? rescue nil
    end

    def self.connect(channel, acting_user)
      raise "connection failed" unless regulations[channel].connectable?(acting_user)
    end

    def self.connections_for(acting_user, auto_connections_only)
      regulations.collect do |channel, regulation|
        next if auto_connections_only && regulation.auto_connect_disabled?
        next if !regulation.connectable?(acting_user)
        channel
      end.compact
    end

    def self.allowed_opts
      [:auto_connect]
    end

  end

  class InstanceConnectionRegulation < Regulation

    def connectable_to(acting_user, auto_connections_only)
      return [] if auto_connections_only && auto_connect_disabled?
      regulate_for(acting_user).entries.compact.flatten(1) rescue []
    end

    def self.connect(instance, acting_user)
      unless regulations[instance].connectable_to(acting_user, false).include? instance
        raise "connection failed"
      end
    end

    def self.connections_for(acting_user, auto_connections_only)
      regulations.collect do |_channel, regulation|
        # the following was bizarelly passing true for auto_connections_only????
        regulation.connectable_to(acting_user, auto_connections_only).collect do |obj|
          if false && auto_connections_only # false added to try to get channel instances to connect???
            [obj.class.name, obj.id]
          else
           InternalPolicy.channel_to_string obj
         end
        end
      end.flatten(1)
    end

    def self.allowed_opts
      [:auto_connect]
    end
  end

  class ChannelBroadcastRegulation < Regulation
    class << self
      def add_regulation(channel, opts={}, &regulation)
        regulations_to_channels[regulation] << super
      end

      def broadcast(policy)
        regulations_to_channels.each do |regulation, channels|
          wrapped_policy = wrap_policy(policy, regulation)
          channels.each do |channel|
            regulation.call wrapped_policy
            policy.send_unassigned_sets_to channel.klass
          end
        end
      end

      def regulations_to_channels
        @regulations_to_channels ||= Hash.new { |hash, key| hash[key] = [] }
      end
    end
  end

  class InstanceBroadcastRegulation < Regulation
    def self.broadcast(instance, policy)
      regulations[instance].regulations.each do |regulation|
        instance.instance_exec wrap_policy(policy, regulation), &regulation
      end
      return if policy.has_to_been_called?

      raise "#{instance.class.name} instance broadcast policy not sent to any channel"
    end
  end

  module AutoConnect
    def self.channels(session, acting_user)
      channels = ClassConnectionRegulation.connections_for(acting_user, true) +
        InstanceConnectionRegulation.connections_for(acting_user, true)
      channels << "Hyperstack::Session-#{session.split('-').last}" if Hyperstack.connect_session && session
      channels.uniq.each { |channel| Connection.open(channel, session) }
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

    def self.raise_operation_access_violation(message, details)
      raise Hyperstack::AccessViolation.new(message, details)
    end

    def self.regulate_connection(acting_user, channel_string)
      channel = channel_string.split("-")
      if channel.length > 1
        id = channel[1..-1].join("-")
        unless Hyperstack::InternalClassPolicy.regulated_klasses.include?(channel[0])
          Hyperstack::InternalPolicy.raise_operation_access_violation(:not_a_channel, "#{channel[0]} is not regulated channel class")
        end
        object = Object.const_get(channel[0]).find(id)
        InstanceConnectionRegulation.connect(object, acting_user)
      else
        ClassConnectionRegulation.connect(channel[0], acting_user)
      end
    end

    def self.regulate_broadcast(model, &block)
      internal_policy = InternalPolicy.new(
        model, model.attribute_names, Connection.active
      )
      ChannelBroadcastRegulation.broadcast(internal_policy)
      InstanceBroadcastRegulation.broadcast(model, internal_policy)
      internal_policy.broadcast &block
    end

    def initialize(obj, attribute_names, available_channels = :all)
      @obj = obj
      @attribute_names = attribute_names.map(&:to_sym).to_set
      @unassigned_send_sets = []
      @channel_sets = Hash.new { |hash, key| hash[key] = @attribute_names }
      @available_channels = available_channels
    end

    def channel_available?(channel)
      return false unless channel
      @available_channels == :all || @available_channels.include?(channel_to_string(channel))
    end

    def id
      @id ||= "#{self.object_id}-#{Time.now.to_f}"
    end

    def has_unassigned_sets?
      !@unassigned_send_sets.empty?
    end

    def send_unassigned_sets_to(channel)
      if channel_available?(channel) && has_unassigned_sets?
        @channel_sets[channel] = @unassigned_send_sets.inject(@channel_sets[channel]) do |set, send_set|
          send_set.merge(set)
        end
      end
      @unassigned_send_sets = []
    end

    def add_unassigned_send_set(send_set)
      @unassigned_send_sets << send_set
    end

    def send_set_to(send_set, channels)
      @to_has_been_called = true
      channels.flatten(1).each do |channel|
        merge_set(send_set, channel) if channel_available? channel
        @unassigned_send_sets.delete(send_set)
      end
    end

    def has_to_been_called?
      !has_unassigned_sets? || @to_has_been_called
    end

    def merge_set(send_set, channel)
      return unless channel
      channel = channel.name if channel.is_a?(Class) && channel.name
      @channel_sets[channel] = send_set.merge(@channel_sets[channel])
    end

    def channel_list
      @channel_sets.collect { |channel, _value| channel_to_string channel }
    end

    def self.channel_to_string(channel)
      if channel.is_a?(Class) && channel.name
        channel.name
      elsif channel.is_a? String
        channel
      else
        "#{channel.class.name}-#{channel.id}"
      end
    end

    def channel_to_string(channel)
      self.class.channel_to_string(channel)
    end

    def filter(h, attribute_set)
      r = {}
      h.each do |key, value|
        r[key.to_sym] = value if attribute_set.member?(key.to_sym) || (key.to_sym == :id)
      end unless attribute_set.empty?
      #model_id = h[:id] || h["id"]
      #r[:id] = model_id if model_id && !attribute_set.empty?
      r
    end

    def send_message(header, channel, attribute_set, &block)
      record = filter(@obj.react_serializer, attribute_set)
      previous_changes = filter(@obj.saved_changes, attribute_set)
      return if record.empty? && previous_changes.empty?
      message = header.merge(
        channel: channel_to_string(channel),
        record: record,
        previous_changes: previous_changes
      )
      yield message
    end

    def broadcast(&block)
      klass = @obj.class
      header = {broadcast_id: id, channels: channel_list, klass: klass.name}
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
    def hyperstack_internal_policy_object
      @hyperstack_internal_policy_object ||= InternalClassPolicy.new(name || self)
    end
    InternalClassPolicy::EXPOSED_METHODS.each do |policy_method|
      define_method policy_method do |*klasses, &block|
        hyperstack_internal_policy_object.send policy_method, *klasses, &block
      end unless respond_to? policy_method
    end
  end

  module PolicyMethods
    def self.included(base)
      base.class_eval do
        extend ClassPolicyMethods
      end
    end
    attr_accessor :hyperstack_internal_policy_object
    InternalPolicy::EXPOSED_METHODS.each do |method|
      define_method method do |*args, &block|
        hyperstack_internal_policy_object.send method, *args, &block
      end unless respond_to? method
    end
    define_method :initialize do |*args|
    end unless instance_methods(false).include?(:initialize)
  end

  module PolicyAutoLoader
    def self.load(name, value)
      const_get("#{name}Policy") if name && !name.end_with?("Policy".freeze) && value.is_a?(Class)
    rescue Exception => e
      raise e if e.is_a?(LoadError) && e.message =~ /Unable to autoload constant #{name}Policy/
    end
  end
end

class Module
  alias pre_hyperstack_const_set const_set

  def const_set(name, value)
    pre_hyperstack_const_set(name, value).tap do
      Hyperstack::PolicyAutoLoader.load(name, value)
    end
  end
end

class Class

  alias pre_hyperstack_inherited inherited

  def inherited(child_class)
    pre_hyperstack_inherited(child_class).tap do
      Hyperstack::PolicyAutoLoader.load(child_class.name, child_class)
    end
  end

  Hyperstack::ClassPolicyMethods.instance_methods.each do |method|
    define_method method do |*args, &block|
      if name.end_with?("Policy".freeze)
        @hyperstack_internal_policy_object = Hyperstack::InternalClassPolicy.new(name.sub(/Policy$/,""))
        include Hyperstack::PolicyMethods
        send method, *args, &block
      else
        class << self
          Hyperstack::ClassPolicyMethods.instance_methods.each do |method|
            undef_method method
          end
        end
        method_missing(method, *args, &block)
      end
    end unless respond_to? method
  end
end
