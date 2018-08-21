class Hyperstack::Resource::ScopesController < ApplicationController
  # introspect available class scopes, like Plan.all or Plan.resolved
  def index
    record_class = guarded_record_class_from_param(record_class_param)

    # TODO security, authorize record_class
    if record_class
      @scopes = record_class.scopes.transform_values { |method| {params: method.arity} }
      @record_name = record_class.to_s.underscore.to_sym
    end
    respond_to { |format| format.json { render(json: {}, status: :unprocessable_entity) if record_class.nil? }}
  end

  def show
    mc_param = record_class_param
    mc_param = mc_param.chop if mc_param.end_with?('s')
    @record_class = guarded_record_class_from_param(mc_param)
    @scope_name = params[:id].to_sym # :id is the scope name
    @collection = nil
    if @record_class && @record_class.scopes.has_key?(@scope_name) # guard
      @collection = @record_class.send(@scope_name)
    end
    respond_to do |format|
      if @record_class && @collection
        format.json
      else
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  def update
    mc_param = record_class_param
    mc_param = mc_param.chop if mc_param.end_with?('s')
    @model_klass = guarded_record_class_from_param(mc_param)
    @scope_name = params[:id].to_sym # :id is the scope name
    @collection = nil
    if @model_klass && @model_klass.scopes.has_key?(@scope_name) # guard
      @collection = @model_klass.send(@scope_name, params[:params])
    end
    respond_to do |format|
      if @model_klass && @collection
        format.json
      else
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  private

  def record_class_param
    params.require(:record_class)
  end
end
