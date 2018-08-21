class Hyperstack::Resource::RelationsController < ApplicationController

  def index
    # introspect available relations
    record_class = guarded_record_class_from_param(record_class_param)
    if record_class
      @collections = record_class.reflections.transform_values { |collection| {
        type: collection.type,
        association: collection.association.type,
        direction: collection.association.direction
      }}
      @record_name = record_class.to_s.underscore.to_sym
    end
    respond_to { |format| format.json { render(status: :unprocessable_entity) if record_class.nil? }}
  end

  def create
    @record, left_id = guarded_record_from_params(params)
    @right_record = nil
    @collection_name = params[:id].to_sym
    @collection = nil
    if @record && @record.class.reflections.has_key?(@collection_name) # guard, :id is the collection name
      right_class_param = if %i[has_many has_and_belongs_to_many].include?(@record.class.reflections[@collection_name].association.type)
                            params[:id].chop # remove the s at the end if its there
                          else
                            params[:id]
                          end
      right_model = guarded_record_class_from_param(right_class_param)
      @right_record = if collection_params(right_model)[:id]
                        right_model.find(collection_params(right_model)[:id])
                      else
                        right_model.create(collection_params(right_model))
                      end
      if @right_record
        if @record.class.reflections[@collection_name].association.type == :has_one
          @record.send("#{@collection_name}=", @right_record)
        else
          @collection = @record.send(@collection_name) # send is guarded above
          @collection << @right_record
        end
      end
    end
    respond_to do |format|
      if @record && @right_record
        @right_record.touch
        @record.touch
        hyper_pub_sub_collection(@collection, @record, @collection_name, @right_record)
        hyper_pub_sub_item(@right_record)
        hyper_pub_sub_item(@record)
        format.json { render status: :created }
      else
        format.json { render json: @right_record ? @right_record.errors : {}, status: :unprocessable_entity }
      end
    end
  end

  def show
    @record, @id = guarded_record_from_params(params)
    # collection result may be nil, so we need have_collection to make sure the collection is valid
    @collection = nil
    have_collection = false
    @collection_name = params[:id].to_sym
    if @record
      # guard, :id is the collection name
      have_collection = @record.class.reflections.has_key?(@collection_name) # for neo4j, key is a symbol
      have_collection = @record.class.reflections.has_key?(params[:id]) unless have_collection # for AR, key is a string
      @collection = @record.send(@collection_name) if have_collection
    end
    respond_to do |format|
      if @record && have_collection
        hyper_sub_collection(@collection, @record, @collection_name)
        hyper_sub_item(@record)
        format.json
      else
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @record, left_id = guarded_record_from_params(params)
    @right_record = nil
    @collection_name = params[:id].to_sym
    @collection = nil
    if @record && @record.class.reflections.has_key?(@collection_name) # guard, :id is the collection name
      right_class_param = params[:id].chop # remove the s at the end
      right_model = guarded_record_class_from_param(right_class_param)
      @right_record = right_model.find(params[:record_id])

      if @right_record
        @collection = @record.send(@collection_name) # send is guarded above
        @collection.delete(@right_record)
      end
    end
    respond_to do |format|
      if @record && @collection
        @right_record.touch
        @record.touch
        hyper_pub_sub_collection(@collection, @record, @collection_name, @right_record)
        hyper_pub_sub_item(@right_record)
        hyper_pub_sub_item(@record)
        format.json { render json: { status: :success } }
      else
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  private

  def record_class_param
    params.require(:record_class)
  end

  def collection_params(record_class)
    permitted_keys = record_class.declared_properties.registered_properties.keys
    %i[created_at updated_at color fixed font scaling shadow].each do |key|
      permitted_keys.delete(key)
    end
    permitted_keys.concat([:id, color: {}, fixed: {}, font: {}, scaling: {}, shadow: {}])
    params.require(:data).permit(permitted_keys)
  end
end
