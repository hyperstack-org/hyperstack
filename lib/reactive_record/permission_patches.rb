# acting user is the acting user... okay

class ActiveRecord::Base
  def view_permitted?(attribute)
    InternalPolicy.accessible_attributes_for(self, acting_user).include? attribute
  end
end

module Synchromesh
  class InternalPolicy

    def channels_for
      @user_channels ||= {}
    end

    def self.accessible_attributes_for(model, acting_user)
      user_channels = ClassConnectionRegulation.connections(acting_user) +
        InstanceConnectionRegulation.connections(acting_user)
      internal_policy = InternalPolicy.new(model, model.attribute_names, user_channels)
      ChannelBroadcastRegulation.broadcast(internal_policy)
      InstanceBroadcastRegulation.broadcast(model, internal_policy)
      internal_policy.accessible_attributes_for(channels)
    end

    def accessible_attributes_for(channels)
      accessible_attributes = Set.new
      @channels_sets.each do |channel, attribute_set|
        accessible_attributes.merge attribute_set
      end
      accessible_attributes
    end
  end
end
