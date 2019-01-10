module Hyperstack
  class ClassConnectionRegulation
    def self.connections(acting_user)
      regulations.collect do |channel, regulation|
        status = regulation.connectable?(acting_user) ? :allowed : :denied
        { type: :class, owner: channel, channel: InternalPolicy.channel_to_string(channel), auto_connect: !regulation.auto_connect_disabled?, status: status }
      end
    end
  end

  class InstanceConnectionRegulation
    def self.connections(acting_user)
      regulations.collect do |channel, regulation|
        regulation.connectable_to(acting_user, false).collect do |obj|
          { type: :instance, owner: channel, channel: InternalPolicy.channel_to_string(obj), auto_connect: !regulation.auto_connect_disabled?, status: :allowed }
        end
      end.flatten(1)
    end
  end

  class InternalPolicy
    def attribute_dump(acting_user)
      # dump[channel]['@channel_status'] -> [owner, type, auto_connect, falsy/no connection/allowed]
      # dump[channel][attribute] -> 'no connection/no channel/no policy/allowed'
      dump = Hash.new { |h, k| h[k] = Hash.new }
      connections = ClassConnectionRegulation.connections(acting_user) +
                    InstanceConnectionRegulation.connections(acting_user)
      connections.each do |status|
        status[:status] = 'allowed' if status[:status]
        status[:status] ||= 'no connection'
        dump[status[:channel]]['@channel_status'] = status
      end
      @channel_sets.each do |channel, attribute_set|
        channel = InternalPolicy.channel_to_string(channel)
        attribute_set.each do |attribute|
          dump[channel]['@channel_status'] ||= { type: 'no channel' }
          dump[channel][attribute] = dump[channel]['@channel_status'][:status] || 'no channel'
        end
      end
      dump.each_key do |channel|
        @attribute_names.each do |attribute|
          dump[channel][attribute] ||= 'no policy'
        end
      end
      dump
    end
  end

  module PolicyDiagnostics
    def self.policy_dump_hash(model, acting_user)
      internal_policy = InternalPolicy.new(model, model.attribute_names, :all)
      ChannelBroadcastRegulation.broadcast(internal_policy)
      InstanceBroadcastRegulation.broadcast(model, internal_policy)
      internal_policy.attribute_dump(acting_user)
    end

    def self.policy_dump_for(model, acting_user)
      dump = policy_dump_hash(model, acting_user)
      attributes = model.attribute_names.map(&:to_sym)
      acting_user_channel = InternalPolicy.channel_to_string(acting_user) if acting_user
      pastel = Pastel.new
      channels = dump.keys.collect do |channel|
        c = channel == acting_user_channel ? "* #{channel} *" : channel
        if dump[channel]['@channel_status'][:status] != 'allowed'
          pastel.red(c)
        elsif channel == acting_user_channel
          pastel.blue(c)
        else
          c
        end
      end
      table = TTY::Table.new header: [''] + channels
      types = dump.keys.collect do |channel|
        type = dump[channel]['@channel_status'][:type]
        type = pastel.red(type) if type == 'no policy'
        type
      end
      table << ['type'] + types
      table << ['auto connect'] + dump.keys.collect { |channel| dump[channel]['@channel_status'][:auto_connect] }
      table << ['status'] + dump.keys.collect { |channel| dump[channel]['@channel_status'][:status] }
      attributes.each do |attribute|
        allowed = false
        statuses = dump.keys.collect do |channel|
          status = dump[channel][attribute]
          if status == 'allowed'
            allowed = true
            status
          else
            pastel.red(status)
          end
        end
        attribute = pastel.red(attribute) unless allowed
        table << [attribute] + statuses
      end
      rendered = table.render(:unicode, indent: 4).split("\n")
      rendered = rendered.insert(6, rendered[2]).join("\n")
      model_string = "<##{model.class} id: #{model.id}>"
      if acting_user
        id = "id: #{acting_user.id}" if acting_user.respond_to? :id
        acting_user_string = "by acting_user <##{acting_user.class} id: #{id}>"
      end
      "    Attribute access policies for #{model_string} #{acting_user_string || 'with no acting_user'}:\n\n"\
      "#{rendered}"
    end
  end
end
