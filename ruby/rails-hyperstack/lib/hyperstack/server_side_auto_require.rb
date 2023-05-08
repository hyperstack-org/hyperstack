# require "hyperstack/server_side_auto_require.rb" in your hyperstack initializer
# to autoload shadowed server side files that match files
# in the hyperstack directory

if Rails.configuration.try(:autoloader) == :zeitwerk
  Rails.autoloaders.each do |loader|
    loader.on_load do |_cpath, _value, abspath|
      ActiveSupport::Dependencies.add_server_side_dependency(abspath) do |load_path|
        loader.send(:log, "Hyperstack loading server side shadowed file: #{load_path}") if loader&.logger
        require("#{load_path}.rb")
      end
    end
  end
end

module ActiveSupport
  module Dependencies
    HYPERSTACK_DIR = "hyperstack"
    class << self
      alias original_require_or_load require_or_load

      # before requiring_or_loading a file, first check if
      # we have the same file in the server side directory
      # and add that as a dependency

      def require_or_load(file_name, const_path = nil)
        add_server_side_dependency(file_name) { |load_path| require_dependency load_path }
        original_require_or_load(file_name, const_path)
      end

      # search the filename path from the end towards the beginning
      # for the HYPERSTACK_DIR directory.  If found, remove it from
      # the filename, and if a ruby file exists at that location then
      # add it as a dependency

      def add_server_side_dependency(file_name, loader = nil)
        path = File.expand_path(file_name.chomp(".rb"))
                   .split(File::SEPARATOR).reverse
        hs_index = path.find_index(HYPERSTACK_DIR)

        return unless hs_index # no hyperstack directory here

        new_path = (path[0..hs_index - 1] + path[hs_index + 1..-1]).reverse
        load_path = new_path.join(File::SEPARATOR)

        return unless File.exist? "#{load_path}.rb"

        yield load_path
      end
    end
  end
end
