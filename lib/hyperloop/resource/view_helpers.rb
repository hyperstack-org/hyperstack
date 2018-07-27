module Hyperloop
  module Resource
    module ViewHelpers
      def hyper_resource_tag(options = {})
        # client side used options:
        # current_user_id
        # session_id
        # form_authenticity_token
        config_hash = Hyperloop.all_options
        config_hash.merge!(options)
        tag = <<~SCRIPT
          <script type="text/javascript">
            window.HyperloopOpts = #{config_hash.to_json};
            Opal.Hyperloop.$const_get('Resource').$const_get('ClientDrivers').$initialize_client_drivers_on_boot();
          </script>
        SCRIPT
        tag
      end
    end
  end
end