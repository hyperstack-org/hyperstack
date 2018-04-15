class Hyperloop::Resource::MethodsController < ApplicationController
  include Hyperloop::Resource::SecurityGuards

  def index
    model_klass = guarded_record_class_from_param(model_klass_param)

    if model_klass
      @methods = model_klass.rest_methods
      @model_name = model_klass.to_s.underscore.to_sym
    end
    respond_to { |format| format.json { render(json: {}, status: :unprocessable_entity) if model_klass.nil? }}
  end

  def show
    result = { error: 'A error occured, wrong method?' }
    error = true
    mc_param = params[:model_klass]
    if mc_param
      # rest_class_method
      mc_param = mc_param.chop if mc_param.end_with?('s')
      @model_klass = guarded_record_class_from_param(mc_param)
      method_name = params[:id].to_sym
      if @model_klass.rest_methods.has_key?(method_name)
        if @model_klass.rest_methods[method_name][:class_method]
          begin
            result = @model_klass.send(method_name)
            error = false
          rescue Exception => e
            Rails.logger.debug e.message
            result = { error: e.message }
            error = true
          end
        end
      end
    else
      # rest_method
      @record, id = guarded_record_from_params(params)
      method_name = params[:id].to_sym
      if @record.class.rest_methods.has_key?(method_name)
        begin
          result = @record.send(method_name)
          error = false
        rescue Exception => e
          Rails.logger.debug e.message
          result = { error: e.message }
          error = true
        end
      end
    end
    respond_to do |format|
      format.json do
        render(json: { result: result }, status: (error ? :unprocessable_entity : 200))
      end
    end
  end

  def update
    result = { error: 'A error occured, wrong method?' }
    error = true
    mc_param = params[:model_klass]
    if mc_param
      # rest_class_method
      mc_param = mc_param.chop if mc_param.end_with?('s')
      @model_klass = guarded_record_class_from_param(mc_param)
      method_name = params[:id].to_sym
      if @model_klass.rest_methods.has_key?(method_name)
        if @model_klass.rest_methods[method_name][:class_method]
          begin
            result = @model_klass.send(method_name, params[:params])
            error = false
          rescue Exception => e
            Rails.logger.debug e.message
            result = { error: e.message }
            error = true
          end
        end
      end
    else
      @record, id = guarded_record_from_params(params)
      method_name = params[:id].to_sym
      if @record.class.rest_methods.has_key?(method_name)
        begin
          result = @record.send(method_name, params[:params])
          error = false
        rescue Exception => e
          Rails.logger.debug e.message
          result = { error: e.message }
          error = true
        end
      end
    end
    respond_to do |format|
      format.json do
        render(json: { result: result }, status: (error ? :unprocessable_entity : 200))
      end
    end
  end

end