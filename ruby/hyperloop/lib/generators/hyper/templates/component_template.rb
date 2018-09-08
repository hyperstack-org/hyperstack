<%- @modules.each do |module_name| %><%= "  "* @indent %>module <%= module_name.camelize %><%- @indent += 1 %>
<%- end %><%="  "* @indent %>class <%= @file_name %> < Hyperloop::Component

<%="  "* @indent %>  # param :my_param
<%="  "* @indent %>  # param param_with_default: "default value"
<%="  "* @indent %>  # param :param_with_default2, default: "default value" # alternative syntax
<%="  "* @indent %>  # param :param_with_type, type: Hash
<%="  "* @indent %>  # param :array_of_hashes, type: [Hash]
<%="  "* @indent %>  # collect_other_params_as :attributes  # collects all other params into a hash

<%="  "* @indent %>  # The following are the most common lifecycle call backs,
<%="  "* @indent %>  # the following are the most common lifecycle call backs# delete any that you are not using.
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
<%="  "* @indent %>    # cleanup any thing (i.e. timers) before component is destroyed
<%="  "* @indent %>  end

<%="  "* @indent %>  render do
<%="  "* @indent %>    DIV do
<%="  "* @indent %>      "<%= (@modules+[@file_name]).join('::') %>"
<%="  "* @indent %>    end
<%="  "* @indent %>  end
<%="  "* @indent %>end
<%- @modules.each do %><%- @indent -= 1 %><%="  "* @indent %>end
<%- end %>
