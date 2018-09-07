module Hyperloop

  class << self
    def import_list
      @import_list ||= []
    end

    def import(value, gem: nil, cancelled: nil, client_only: nil, server_only: nil, tree: nil, js_import: nil, at_head: nil)
      return if import_list.detect { |current_value, *_rest| value == current_value }
      new_element = [
        value, cancelled, !client_only, !server_only, (tree ? :tree : :gem), js_import
      ]
      import_list.send(at_head ? :unshift : :push, new_element)
    end

    alias imports import

    def import_tree(value, cancelled: nil, client_only: nil, server_only: nil)
      import(value, cancelled: cancelled, client_only: client_only, server_only: server_only, tree: true)
    end

    def cancel_import(value)
      return unless value
      current_spec = import_list.detect { |old_value, *_rest| value == old_value }
      if current_spec
        current_spec[1] = true
      else
        import_list << [value, true, true, true, false]
      end
    end

    def cancel_webpack_imports
      import_list.collect { |name, _c, _co, _so, _t, js_import, *_rest| js_import && name }
                 .each { |name| cancel_import name }
    end

    def handle_webpack
      return unless defined? Webpacker
      client_only_manifest = Webpacker.manifest.lookup("client_only.js")
      client_and_server_manifest = Webpacker.manifest.lookup("client_and_server.js")
      return unless client_only_manifest || client_and_server_manifest
      cancel_webpack_imports
      import client_only_manifest.split("/").last, client_only: true, at_head: true if client_only_manifest
      import client_and_server_manifest.split("/").last, at_head: true if client_and_server_manifest
    end

    def generate_requires(mode, sys, file)
      handle_webpack
      import_list.collect do |value, cancelled, render_on_server, render_on_client, kind|
        next if cancelled
        next if (sys && kind == :tree) || (!sys && kind != :tree)
        next if mode == :client && !render_on_client
        next if mode == :server && !render_on_server
        if kind == :tree
          generate_require_tree(value, render_on_server, render_on_client)
        elsif kind == :gem
          r = "require '#{value}' #{client_guard(render_on_server, render_on_client)}"
          puts "    #{r}"
          "puts \"#{r}\"; #{r}"
        else
          generate_directive(:require, value, file, render_on_server, render_on_client)
        end
      end.compact.join("\n")
    end

    def generate_directive(directive, to, file, render_on_server, render_on_client)
      gem_path = File.expand_path('../', file).split('/')
      comp_path = Rails.root.join('app', 'hyperloop', to).to_s.split('/')
      while comp_path.first == gem_path.first do
        gem_path.shift
        comp_path.shift
      end
      r = "#{directive} '#{(['.'] + ['..'] * gem_path.length + comp_path).join('/')}' #{client_guard(render_on_server, render_on_client)}"
      puts "    #{r}"
      "puts \"#{r}\"; #{r}"
    end

    def generate_require_tree(path, render_on_server, render_on_client)
      base_name = Rails.root.join('app', path).to_s+'/'
      Dir.glob(Rails.root.join('app', path, '**', '*')).sort.collect do |fname|
        fname = fname.gsub(/^#{base_name}/, '')
        fname = fname.gsub(/\.erb$/, '')
        if fname =~ /(\.js$)|(\.rb$)/
          fname = fname.gsub(/(\.js$)|(\.rb$)/, '')
          r = "require '#{fname}' #{client_guard(render_on_server, render_on_client)}"
          puts "    #{r}"
          "puts \"#{r}\"; #{r}"
        end
      end.compact.join("\n")
    end

    def client_guard(render_on_server, render_on_client)
      if !render_on_server
        '# CLIENT ONLY'
      elsif !render_on_client
        '# SERVER ONLY'
      end
    end

    Hyperloop.define_setting(:compress_system_assets, true) do
       puts "INFO: The configuration option 'compress_system_assets' is no longer used."
    end
  end
end
