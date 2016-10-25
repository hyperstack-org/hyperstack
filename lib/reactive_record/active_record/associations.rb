module ActiveRecord

  class Base

    def self.reflect_on_all_associations
      base_class.instance_eval { @associations ||= superclass.instance_eval { (@associations && @associations.dup) || [] } }
    end

    def self.reflect_on_association(attribute)
      if found = reflect_on_all_associations.detect { |association| association.attribute == attribute and association.owner_class == self }
        found
      elsif superclass == Base
        nil
      else
        superclass.reflect_on_association(attribute)
      end
    end

  end

  module Associations

    class AssociationReflection

      attr_reader :association_foreign_key
      attr_reader :attribute
      attr_reader :macro
      attr_reader :owner_class

      def initialize(owner_class, macro, name, options = {})
        owner_class.reflect_on_all_associations << self
        @owner_class = owner_class
        @macro =       macro
        @options =     options
        @klass_name =  options[:class_name] || (collection? && name.camelize.gsub(/s$/,"")) || name.camelize
        if @klass_name < ActiveRecord::Base
          @klass = @klass_name
          @klass_name = @klass_name.name
        end rescue nil
        @association_foreign_key = options[:foreign_key] || (macro == :belongs_to && "#{name}_id") || "#{@owner_class.name.underscore}_id"
        @attribute =   name
      end

      def inverse_of
        unless @options[:through] or @inverse_of
          inverse_association = klass.reflect_on_all_associations.detect do | association |
            association.association_foreign_key == @association_foreign_key and association.klass == @owner_class and association.attribute != attribute and klass == association.owner_class
          end
          raise "Association #{@owner_class}.#{attribute} (foreign_key: #{@association_foreign_key}) has no inverse in #{@klass_name}" unless inverse_association
          @inverse_of = inverse_association.attribute
        end
        @inverse_of
      end

      def klass
        @klass ||= Object.const_get(@klass_name)
      end

      def collection?
        [:has_many].include? @macro
      end

    end

  end


end
