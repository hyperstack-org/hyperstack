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
      tag.respond_to?(:html_safe) ? tag.html_safe : tag
    end

    def hyper_component(component_name, params)
      component_name_id = component_id_name(component_name)
      tag = <<~SCRIPT
        <div id="#{component_name_id}"></div>
        <script type="text/javascript">
          var component = Opal.Object.$const_get("#{component_name}");
          var json_params = #{Oj.dump(params)};
          Opal.Hyperstack.$const_get('TopLevel').$mount(component, Opal.Hash.$new(json_params), "##{component_name_id}" );
        </script>
      SCRIPT
      tag.respond_to?(:html_safe) ? tag.html_safe : tag
    end

    private

    def component_id_name(component_name)
      "#{component_name.underscore}_#{Random.rand.to_s[2..-1]}"
    end
  end
end