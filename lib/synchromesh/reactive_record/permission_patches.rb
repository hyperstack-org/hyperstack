# acting user is the acting user... okay

class ActiveRecord::Base

  def view_permitted?(attribute)
    HyperMesh::InternalPolicy.accessible_attributes_for(self, acting_user).include? attribute.to_sym
  end

  def create_permitted?
    false
  end

  def update_permitted?
    false
  end

  def destroy_permitted?
    false
  end
end

module HyperMesh
  class InternalPolicy

    def self.accessible_attributes_for(model, acting_user)
      user_channels = ClassConnectionRegulation.connections_for(acting_user, false) +
        InstanceConnectionRegulation.connections_for(acting_user, false)
      internal_policy = InternalPolicy.new(model, model.attribute_names, user_channels)
      ChannelBroadcastRegulation.broadcast(internal_policy)
      InstanceBroadcastRegulation.broadcast(model, internal_policy)
      internal_policy.accessible_attributes_for
    end

    def accessible_attributes_for
      accessible_attributes = Set.new
      @channel_sets.each do |channel, attribute_set|
        accessible_attributes.merge attribute_set
      end
      accessible_attributes << :id unless accessible_attributes.empty?
      accessible_attributes
    end
  end
end
