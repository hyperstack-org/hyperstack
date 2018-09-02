module HyperI18n
  class Translate < Hyperloop::ServerOp
    param :acting_user, nils: true
    param :attribute
    param :opts
    param :translation, default: nil

    def opts
      params.opts.with_indifferent_access
    end

    step do
      params.translation = ::I18n.t(params.attribute, opts)
    end
  end
end
