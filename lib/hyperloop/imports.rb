module Hyperloop
  class << self
    def import_list
      @import_list ||= []
    end

    def import(value, gem: nil, instead_of: nil, client_only: nil, server_only: nil, tree: nil)
      if instead_of
        current_spec = import_list.detect { |old_value, *_rest| instead_of == old_value }
        if current_spec
          current_spec[0] = value
        else
          raise [
            "Could not substitute import '#{instead_of}' with '#{value}'.  '#{instead_of}' not found.",
            'The following files are currently being imported:',
            *import_list.collect { |old_value, *_rest| old_value }
          ].join("\n")
        end
      elsif !import_list.detect { |current_value, *_rest| value == current_value }
        kind = if tree
                 :tree
               else
                 :gem
               end
        import_list << [value, !client_only, !server_only, kind]
      end
    end

    alias imports import

    def import_tree(value, instead_of: nil, client_only: nil, server_only: nil)
      import(value, instead_of: instead_of, client_only: client_only, server_only: server_only, tree: true)
    end

    def cancel_import(value)
      import(nil, instead_of: value)
    end

    def generate_requires(mode, sys, file)
      puts "***** generating requires for #{mode} - #{file}"
      import_list.collect do |value, render_on_server, render_on_client, kind|
        next unless value
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
      Dir.glob(Rails.root.join('app', path, '**', '*')).collect do |fname|
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

    def compile_and_compress(name)
      start_time = Time.now
      puts "Compiling the system assets for #{name}"
      compiled_code = Rails.application.assets[name].to_s
      compilation_time = Time.now
      puts "  compiled -  length: #{compiled_code.length}"
      compressed_code = Uglifier.new.compile(compiled_code)
      puts "  minimized - length: #{compressed_code.length}"
      puts "  minification ratio #{(compressed_code.length*100.0/compiled_code.length).round}%"
      puts "  total time: #{(Time.now-start_time).to_f.round(2)} seconds"
      compressed_code
    end

  end
end
