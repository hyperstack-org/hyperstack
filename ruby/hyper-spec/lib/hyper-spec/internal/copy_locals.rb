module HyperSpec
  module Internal
    module CopyLocals
      private

      def build_var_inclusion_lists
        build_included_list
        build_excluded_list
      end

      def build_included_list
        @_hyperspec_private_included_vars = nil
        return unless @_hyperspec_private_client_options.key? :include_vars

        included = @_hyperspec_private_client_options[:include_vars]
        if included.is_a? Symbol
          @_hyperspec_private_included_vars = [included]
        elsif included.is_a?(Array)
          @_hyperspec_private_included_vars = included
        elsif !included
          @_hyperspec_private_included_vars = []
        end
      end

      PRIVATE_VARIABLES = %i[
        @__inspect_output @__memoized @example @_hyperspec_private_client_code
        @_hyperspec_private_html_block @fixture_cache
        @fixture_connections @connection_subscriber @loaded_fixtures
        @_hyperspec_private_client_options
        @_hyperspec_private_included_vars
        @_hyperspec_private_excluded_vars
        b __ _ _ex_ pry_instance _out_ _in_ _dir_ _file_
      ]

      def build_excluded_list
        return unless @_hyperspec_private_client_options

        excluded = @_hyperspec_private_client_options[:exclude_vars]
        if excluded.is_a? Symbol
          @_hyperspec_private_excluded_vars = [excluded]
        elsif excluded.is_a?(Array)
          @_hyperspec_private_excluded_vars = excluded
        elsif excluded
          @_hyperspec_private_included_vars = []
        end
      end

      def var_excluded?(var, binding)
        return true if PRIVATE_VARIABLES.include? var

        excluded = binding.eval('instance_variable_get(:@_hyperspec_private_excluded_vars)')
        return true if excluded&.include?(var)

        included = binding.eval('instance_variable_get(:@_hyperspec_private_included_vars)')
        included && !included.include?(var)
      end

      def add_locals(in_str, block)
        b = block.binding
        add_instance_vars(b, add_local_vars(b, add_memoized_vars(b, in_str)))
      end

      def add_memoized_vars(binding, in_str)
        memoized = binding.eval('__memoized').instance_variable_get(:@memoized)
        return in_str unless memoized

        memoized.inject(in_str) do |str, pair|
          next str if var_excluded?(pair.first, binding)

          "#{str}\n#{set_local_var(pair.first, pair.last)}"
        end
      end

      def add_local_vars(binding, in_str)
        binding.local_variables.inject(in_str) do |str, var|
          next str if var_excluded?(var, binding)

          "#{str}\n#{set_local_var(var, binding.local_variable_get(var))}"
        end
      end

      def add_instance_vars(binding, in_str)
        binding.eval('instance_variables').inject(in_str) do |str, var|
          next str if var_excluded?(var, binding)

          "#{str}\n#{set_local_var(var, binding.eval("instance_variable_get('#{var}')"))}"
        end
      end

      def set_local_var(name, object)
        serialized = object.opal_serialize
        if serialized
          "#{name} = #{serialized}"
        else
          "self.class.define_method(:#{name}) "\
          "{ raise 'Attempt to access the variable #{name} "\
          'that was defined in the spec, but its value could not be serialized '\
          "so it is undefined on the client.' }"
        end
      end
    end
  end
end
