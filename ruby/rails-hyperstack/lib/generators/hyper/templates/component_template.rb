<%- @modules.each do |module_name| %><%= "  "* @indent %>module <%= module_name.camelize %><%- @indent += 1 %>
<%- end %><%="  "* @indent %>class <%= @file_name %> < <%= @component_base_class %>
<%- unless @no_help %>
<%="  "* @indent %>  # param :my_param
<%="  "* @indent %>  # param param_with_default: "default value"
<%="  "* @indent %>  # param :param_with_default2, default: "default value" # alternative syntax
<%="  "* @indent %>  # param :param_with_type, type: Hash
<%="  "* @indent %>  # param :array_of_hashes, type: [Hash]
<%="  "* @indent %>  # other :attributes  # collects all other params into a hash
<%="  "* @indent %>  # fires :callback  # creates a callback param

<%="  "* @indent %>  # access params using the param name
<%="  "* @indent %>  # fire a callback using the callback name followed by a !

<%="  "* @indent %>  # state is kept and read as normal instance variables
<%="  "* @indent %>  # but when changing state prefix the statement with `mutate`
<%="  "* @indent %>  # i.e. mutate @my_state = 12
<%="  "* @indent %>  #      mutate @my_other_state[:bar] = 17

<%="  "* @indent %>  # the following are the most common lifecycle call backs,
<%="  "* @indent %>  # delete any that you are not using.
<%="  "* @indent %>  # call backs may also reference an instance method i.e. before_mount :my_method

<%="  "* @indent %>  before_mount do
<%="  "* @indent %>    # any initialization particularly of state variables goes here.
<%="  "* @indent %>    # this will execute on server (prerendering) and client.
<%="  "* @indent %>  end

<%="  "* @indent %>  after_mount do
<%="  "* @indent %>    # any client only post rendering initialization goes here.
<%="  "* @indent %>    # i.e. start timers, HTTP requests, and low level jquery operations etc.
<%="  "* @indent %>  end

<%="  "* @indent %>  before_update do
<%="  "* @indent %>    # called whenever a component will be re-rerendered
<%="  "* @indent %>  end

<%="  "* @indent %>  before_unmount do
<%="  "* @indent %>    # cleanup any thing before component is destroyed
<%="  "* @indent %>    # note timers are broadcast receivers are cleaned up
<%="  "* @indent %>    # automatically
<%="  "* @indent %>  end

<%- end %><%="  "* @indent %>  render do
<%="  "* @indent %>    DIV do
<%="  "* @indent %>      '<%= (@modules+[@file_name]).join('::') %>'
<%="  "* @indent %>    end
<%="  "* @indent %>  end
<%="  "* @indent %>end
<%- @modules.each do %><%- @indent -= 1 %><%="  "* @indent %>end
<%- end %>
