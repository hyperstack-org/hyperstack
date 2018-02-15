require 'set'

module Hyperloop
  class Autoloader
    # All files ever loaded.
    def self.history=(a)
      @@history = a
    end
    def self.history
      @@history
    end
    self.history = Set.new

    def self.load_paths=(a)
      @@load_paths = a
    end
    def self.load_paths
      @@load_paths
    end
    self.load_paths = []

    def self.loaded=(a)
      @@loaded = a
    end
    def self.loaded
      @@loaded
    end
    self.loaded = Set.new

    def self.loading=(a)
      @@loading = a
    end
    def self.loading
      @@loading
    end
    self.loading = []

    def self.const_missing(const_name, mod)
      # name.nil? is testing for anonymous
      from_mod = mod.name.nil? ? guess_for_anonymous(const_name) : mod
      load_missing_constant(from_mod, const_name)
    end

    def self.guess_for_anonymous(const_name)
      if Object.const_defined?(const_name)
        raise NameError.new "#{const_name} cannot be autoloaded from an anonymous class or module", const_name
      else
        Object
      end
    end

    def self.load_missing_constant(from_mod, const_name)
      # see active_support/dependencies.rb in case of reloading on how to handle
      qualified_name = qualified_name_for(from_mod, const_name)
      qualified_path = underscore(qualified_name)

      module_path = search_for_module(qualified_path)
      if module_path
        if loading.include?(module_path)
          raise "Circular dependency detected while autoloading constant #{qualified_name}"
        else
          require_or_load(from_mod, module_path)
          raise LoadError, "Unable to autoload constant #{qualified_name}, expected #{module_path} to define it" unless from_mod.const_defined?(const_name, false)
          return from_mod.const_get(const_name)
        end
      elsif (parent = from_mod.parent) && parent != from_mod &&
            ! from_mod.parents.any? { |p| p.const_defined?(const_name, false) }
        begin
          return parent.const_missing(const_name)
        rescue NameError => e
          raise unless missing_name?(e, qualified_name_for(parent, const_name))
        end
      end
    end

    def self.missing_name?(e, name)
      mn = if /undefined/ !~ e.message
             $1 if /((::)?([A-Z]\w*)(::[A-Z]\w*)*)$/ =~ e.message
           end
      mn == name
    end

    # Returns the constant path for the provided parent and constant name.
    def self.qualified_name_for(mod, name)
      mod_name = to_constant_name(mod)
      mod_name == 'Object' ? name.to_s : "#{mod_name}::#{name}"
    end

    def self.require_or_load(from_mod, module_path)
      return if loaded.include?(module_path)
      loaded << module_path
      loading << module_path

      begin
        result = require module_path
      rescue Exception
        loaded.delete module_path
        raise LoadError, "Unable to autoload: require_or_load #{module_path} failed"
      ensure
        loading.pop
      end

      # Record history *after* loading so first load gets warnings.
      history << module_path
      result
      # end
    end

    def self.search_for_module(path)
      # oh my! imagine Bart Simpson, writing on the board:
      # "javascript is not ruby, javascript is not ruby, javascript is not ruby, ..."
      # then running home, starting irb, on the fly developing a chat client and opening a session with Homer at his workplace: "Hi Dad ..."
      load_paths.each do |load_path|
        mod_path = load_path + '/' + path
        return mod_path if `Opal.modules.hasOwnProperty(#{mod_path})`
      end
      return path if `Opal.modules.hasOwnProperty(#{path})`
      nil # Gee, I sure wish we had first_match ;-)
    end

    # Convert the provided const desc to a qualified constant name (as a string).
    # A module, class, symbol, or string may be provided.
    def self.to_constant_name(desc) #:nodoc:
      case desc
      when String then desc.sub(/^::/, '')
      when Symbol then desc.to_s
      when Module
        desc.name ||
          raise(ArgumentError, 'Anonymous modules have no name to be referenced by')
      else raise TypeError, "Not a valid constant descriptor: #{desc.inspect}"
      end
    end

    def self.underscore(string)
      string.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
    end
  end
end
