module HyperI18n
  class Localize < Hyperloop::ServerOp
    include HelperMethods

    param :acting_user, nils: true
    param :date_or_time
    param :format
    param :opts
    param :localization, default: nil

    def date_or_time
      @date_or_time ||= formatted_date_or_time(params.date_or_time)
    end

    def opts
      @opts ||= params.opts.with_indifferent_access.merge(format: formatted_format(params.format))
    end

    step do
      params.localization = ::I18n.l(date_or_time, opts)
    end
  end
end
