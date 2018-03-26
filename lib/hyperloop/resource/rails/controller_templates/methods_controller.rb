class Hyperloop::Resource::MethodsController < ApplicationController
  include Hyperloop::Resource::SecurityGuards
  
  def index
    # used for introspection
    record_class = guarded_record_class_from_param(record_class_param)
    if record_class
      @methods = record_class.rest_methods
      @record_name = record_class.to_s.underscore.to_sym
    end
    respond_to { |format| format.json { render(json: {}, status: :unprocessable_entity) if record_class.nil? }}
  end

  def show
    @record, id = guarded_record_from_params(params)
    method_name = params[:id].to_sym
    result = { error: 'A error occured, wrong method?' }
    error = true
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
    respond_to do |format|
      format.json do
        render(json: { result: result }, status: (error ? :unprocessable_entity : 200))
      end
    end
  end

  def update
    @record, id = guarded_record_from_params(params)
    method_name = params[:id].to_sym
    result = { error: 'A error occured, wrong method?' }
    error = true
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
    respond_to do |format|
      format.json do
        render(json: { result: result }, status: (error ? :unprocessable_entity : 200))
      end
    end
  end

  private
  
  def record_class_param
    params.require(:record_class)
  end
end
