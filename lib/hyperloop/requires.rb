module Hyperloop
  class << self
    def requires
      @requires ||= []
    end

    def require(value, gem: nil, override_with: nil, client_only: nil, tree: nil)
      if override_with
        define_class_method "#{override_with}=" do |value|
          requires.detect do |name, _value, _client_only, _kind|
            name == override_with
          end[1] = value
        end
      end
      kind = if gem
        :gem
      elsif tree
        :tree
      end
      requires << [override_with, value, client_only, kind]
    end

    def require_tree(value, override_with: nil, client_only: nil)
      require(value, override_with: override_with, client_only: client_only, tree: true)
    end

    def require_gem(value, override_with: nil, client_only: nil)
      require(value, override_with: override_with, client_only: client_only, gem: true)
    end

    def generate_requires(mode, file)
      puts "***** generating requires for #{mode} - #{file}"
      requires.collect do |name, value, client_only, kind|
        next unless value
        next if client_only && mode != :client
        if kind == :tree
          generate_require_tree(value, client_only)
        elsif kind == :gem
          r = "require '#{value}' #{client_guard(client_only)}"
          puts r
          "puts \"#{r}\"; #{r}"
        else
          generate_directive(:require, value, file, client_only)
        end
      end.compact.join("\n")
    end

    def generate_directive(directive, to, file, client_only = false)
      gem_path = File.expand_path('../', file).split('/')
      comp_path = Rails.root.join('app', 'hyperloop', to).to_s.split('/')
      while comp_path.first == gem_path.first do
        gem_path.shift
        comp_path.shift
      end
      r = "#{directive} '#{(['.'] + ['..'] * gem_path.length + comp_path).join('/')}' #{client_guard(client_only)}"
      puts r
      "puts \"#{r}\"; #{r}"
    end

    def generate_require_tree(path, client_only)
      base_name = Rails.root.join('app', path).to_s+'/'
      Dir.glob(Rails.root.join('app', path, '**', '*')).collect do |fname|
        if ['.js', '.rb', '.erb'].include? File.extname(fname)
          r = "require '#{fname.gsub(base_name, '')}' #{client_guard(client_only)}"
          puts r
          "puts \"#{r}\"; #{r}"
        end
      end.compact.join("\n")
    end

    def client_guard(client_only)
      "# CLIENT ONLY" if client_only
    end

  end
end
