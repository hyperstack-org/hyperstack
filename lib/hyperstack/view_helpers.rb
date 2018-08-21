module Hyperstack
  module ViewHelpers
    def hyper_script_tag(options = {})
      # client side used options:
      # current_user_id
      # session_id
      # form_authenticity_token
      options_hash = Hyperstack.options_hash_for_client
      options_hash.merge!(options)
      tag = <<~SCRIPT
        <script type="text/javascript">
          Opal.HyperstackOptions = #{options_hash.to_json};
          Opal.Hyperstack.$init();
        </script>
      SCRIPT
      tag
    end
  end
end