require 'reactive_record/server_data_cache'

module ReactiveRecord

  class ReactiveRecordController < ::ApplicationController

    def fetch
      render :json => ReactiveRecord::ServerDataCache[
        (json_params[:models] || []).map(&:with_indifferent_access),
        (json_params[:associations] || []).map(&:with_indifferent_access),
        json_params[:pending_fetches],
        acting_user
      ]
    rescue Exception => e
      render json: {error: e.message, backtrace: e.backtrace}, status: 500
    end

    def save
      render :json => ReactiveRecord::Base.save_records(
        (json_params[:models] || []).map(&:with_indifferent_access),
        (json_params[:associations] || []).map(&:with_indifferent_access),
        acting_user,
        json_params[:validate],
        true
      )
    rescue Exception => e
      render json: {error: e.message, backtrace: e.backtrace}, status: 500
    end

    def destroy
      render :json => ReactiveRecord::Base.destroy_record(
        json_params[:model],
        json_params[:id],
        json_params[:vector],
        acting_user
      )
    rescue Exception => e
      render json: {error: e.message, backtrace: e.backtrace}, status: 500
    end

    private

    def json_params
      JSON.parse(params[:json]).symbolize_keys
    end

  end

end
