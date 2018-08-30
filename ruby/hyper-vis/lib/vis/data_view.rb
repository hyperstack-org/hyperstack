module Vis
  class DataView
    include Native
    include Vis::Utilities
    include Vis::EventSupport
    include Vis::DataCommon

    aliases_native %i[refresh length]
    alias :size :length

    attr_reader :event_handlers

    def initialize(data_set_or_view, options = {})
      native_options = options_to_native(options)
      @data_set_or_view = data_set_or_view
      @event_handlers = {}
      @native = `new vis.DataView(data_set_or_view.$to_n(), native_options)`
    end

    def get_data_set
      @data_set_or_view
    end

    def set_data(data_set_or_view)
      @data_set_or_view = data_set_or_view
      @native.JS.setData(data_set_or_view.to_n)
    end
  end
end