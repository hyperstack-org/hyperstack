module HyperI18n
  class Translate < Hyperloop::ServerOp
    param :acting_user
    param :attribute
    param :translation, default: nil

    step do
      params.translation = ::I18n.t(params.attribute)
    end
  end
end
