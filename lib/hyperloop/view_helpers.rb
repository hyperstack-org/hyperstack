module Hyperloop
  module ViewHelpers
    def hyper_script_tag(options = {})
      # client side used options:
      # current_user_id
      # session_id
      # form_authenticity_token
      options_hash = Hyperloop.options_hash_for_client
      options_hash.merge!(options)
      # TODO needs array of initializers to call instead of the hard coded const
      tag = <<~SCRIPT
        <script type="text/javascript">
          Opal.HyperloopOpts = #{options_hash.to_json};
          Opal.Hyperloop.$init_options();
          if (#{Object.const_defined?('Hyperloop::Transport::ClientDrivers')}) {
            Opal.Hyperloop.$const_get('Transport').$const_get('ClientDrivers').$initialize_client_drivers_on_boot();
          }
        </script>
      SCRIPT
      tag
    end
  end
end