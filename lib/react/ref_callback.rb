require 'react/native_library'

module React
  module RefsCallbackExtension
  end

  class API
    class << self
      alias :orig_convert_props :convert_props
    end

    def self.convert_props(properties)
      props = self.orig_convert_props(properties)
      props.map do |key, value|
        if key == "ref" && value.is_a?(Proc)
          new_proc = Proc.new do |native_inst|
            if `#{native_inst}._getOpalInstance !== undefined && #{native_inst}._getOpalInstance !== null`
              value.call(`#{native_inst}._getOpalInstance()`)
            elsif `React.findDOMNode !== undefined && #{native_inst}.nodeType === undefined`
              value.call(`React.findDOMNode(#{native_inst})`)
            else
              value.call(native_inst)
            end
          end
          props[key] = new_proc
        end
      end
      props
    end
  end
end
