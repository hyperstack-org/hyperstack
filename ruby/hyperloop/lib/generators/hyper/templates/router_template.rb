<%- @modules.each do |module_name| %><%= "  "* @indent %>module <%= module_name.camelize %><%- @indent += 1 %>
<%- end %><%="  "* @indent %>class <%= @file_name %> < Hyperloop::Router
<%="  "* @indent %>
<%="  "* @indent %>  route do
<%="  "* @indent %>    DIV do
<%="  "* @indent %>      "<%= (@modules+[@file_name]).join('::') %>"
<%="  "* @indent %>      # define routes using the Route psuedo component.  Examples:
<%="  "* @indent %>      # Route('/foo', mounts: Foo)                : match the path beginning with /foo and mount component Foo here
<%="  "* @indent %>      # Route('/foo') { Foo(...) }                : display the contents of the block
<%="  "* @indent %>      # Route('/', exact: true, mounts: Home)     : match the exact path / and mount the Home component
<%="  "* @indent %>      # Route('/user/:id/name', mounts: UserName) : path segments beginning with a colon will be captured in the match param
<%="  "* @indent %>      # see the hyper-router gem documentation for more details
<%="  "* @indent %>    end
<%="  "* @indent %>  end
<%="  "* @indent %>end
<%- @modules.each do %><%- @indent -= 1 %><%="  "* @indent %>end
<%- end %>
