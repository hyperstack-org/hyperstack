module HyperSpec
  module ComponentTestHelpers
    def attributes_on_client(model)
      evaluate_ruby("#{model.class.name}.find(#{model.id}).attributes").symbolize_keys
    end
  end
end
