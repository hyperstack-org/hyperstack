module Unparser
  class Emitter
    # Emitter for send
    class Send < self
      def local_variable_clash?
        selector =~ /^[A-Z]/ || local_variable_scope.local_variable_defined_for_node?(node, selector)
      end
    end
  end
end

module MethodSource
  class << self
    alias original_lines_for_before_hyper_spec lines_for
    alias original_source_helper_before_hyper_spec source_helper

    def source_helper(source_location, name=nil)
      source_location[1] = 1 if source_location[0] == '(pry)'
      original_source_helper_before_hyper_spec source_location, name
    end

    def lines_for(file_name, name = nil)
      if file_name == '(pry)'
        HyperSpec.current_pry_code_block
      else
        original_lines_for_before_hyper_spec file_name, name
      end
    end
  end
end

class Object
  def opal_serialize
    nil
  end
end

class Hash
  def opal_serialize
    "{#{collect { |k, v| "#{k.opal_serialize} => #{v.opal_serialize}"}.join(', ')}}"
  end
end

class Array
  def opal_serialize
    "[#{collect { |v| v.opal_serialize }.join(', ')}]"
  end
end

[FalseClass, Float, Integer, NilClass, String, Symbol, TrueClass].each do |klass|
  klass.send(:define_method, :opal_serialize) do
    inspect
  end
end

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.4.0')
  [Bignum, Fixnum].each do |klass|
    klass.send(:define_method, :opal_serialize) do
      inspect
    end
  end
end

class Time
  def to_opal_expression
    "Time.parse('#{inspect}')"
  end
end
