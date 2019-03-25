module HyperI18n
  class Translate < Hyperstack::ServerOp
    param :acting_user, nils: true
    param :attribute
    param :opts
    param :translation, default: nil

    def opts
      params.opts.symbolize_keys
    end

    step do
      params.translation = ::I18n.t(params.attribute, opts)
    end
  end
end
