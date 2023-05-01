Rails.configuration.autoloader = :classic #:zeitwerk

module ActiveSupport
  module Dependencies
    HYPERSTACK_DIR = "hyperstack"
    class << self
      alias original_require_or_load require_or_load

      # before requiring_or_loading a file, first check if
      # we have the same file in the server side directory
      # and add that as a dependency

      def require_or_load(file_name, const_path = nil)
        add_server_side_dependency(file_name)
        original_require_or_load(file_name, const_path)
      end

      # search the filename path from the end towards the beginning
      # for the HYPERSTACK_DIR directory.  If found, remove it from
      # the filename, and if a ruby file exists at that location then
      # add it as a dependency

      def add_server_side_dependency(file_name)
        path = File.expand_path(file_name.chomp(".rb"))
                   .split(File::SEPARATOR).reverse
        hs_index = path.find_index(HYPERSTACK_DIR)

        return unless hs_index # no hyperstack directory here

        new_path = (path[0..hs_index - 1] + path[hs_index + 1..-1]).reverse
        load_path = new_path.join(File::SEPARATOR)

        return unless File.exist? "#{load_path}.rb"

        require_dependency load_path
      end
    end
  end
end
