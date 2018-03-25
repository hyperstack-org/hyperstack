class Hyperloop::Resource::PropertiesController < ApplicationController
  include Hyperloop::Resource::SecurityGuards
  
  def index
    # introspect available class scopes
    record_class = guarded_record_class_from_param(record_class_param)
    if record_class
      @properties = record_class.declared_properties.registered_properties.transform_values do |property_hash| 
        { type: property_hash[:type] }
      end
      @record_name = record_class.to_s.underscore.to_sym
    end
    respond_to { |format| format.json { render(json: {}, status: :unprocessable_entity) if record_class.nil? }}
  end

  private
  
  def record_class_param
    params.require(:record_class)
  end
end
