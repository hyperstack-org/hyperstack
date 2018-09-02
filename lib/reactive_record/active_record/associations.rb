module ActiveRecord

  class Base

    def self.reflect_on_all_associations
      base_class.instance_eval { @associations ||= superclass.instance_eval { (@associations && @associations.dup) || [] } }
    end

    def self.reflect_on_association(attr)
      reflection_finder { |assoc| assoc.attribute == attr }
    end

    def self.reflect_on_association_by_foreign_key(key)
      reflection_finder { |assoc| assoc.association_foreign_key == key }
    end

    def self.reflection_finder(&block)
      found = reflect_on_all_associations.detect do |assoc|
        assoc.owner_class == self && yield(assoc)
      end
      if found
        found
      elsif superclass == Base
        nil
      else
        superclass.reflection_finder(&block)
      end
    end

  end

  module Associations

    class AssociationReflection

      attr_reader :association_foreign_key
      attr_reader :attribute
      attr_reader :macro
      attr_reader :owner_class
      attr_reader :source

      def initialize(owner_class, macro, name, options = {})
        owner_class.reflect_on_all_associations << self
        @owner_class = owner_class
        @macro =       macro
        @options =     options
        @klass_name =  options[:class_name] || (collection? && name.camelize.sub(/s$/, '')) || name.camelize
        @association_foreign_key = options[:foreign_key] || (macro == :belongs_to && "#{name}_id") || "#{@owner_class.name.underscore}_id"
        @source = options[:source] || @klass_name.underscore if options[:through]
        @attribute = name
      end

      def through_association
        return unless @options[:through]
        @through_association ||= @owner_class.reflect_on_all_associations.detect do |association|
          association.attribute == @options[:through]
        end
        raise "Through association #{@options[:through]} for "\
              "#{@owner_class}.#{attribute} not found." unless @through_association
        @through_association
      end

      alias through_association? through_association

      def through_associations
        # find all associations that use the inverse association as the through association
        # that is find all associations that are using this association in a through relationship
        @through_associations ||= klass.reflect_on_all_associations.select do |assoc|
          assoc.through_association && assoc.inverse == self
        end
      end

      def source_associations
        # find all associations that use this association as the source
        # that is final all associations that are using this association as the source in a
        # through relationship
        @source_associations ||= owner_class.reflect_on_all_associations.collect do |sibling|
          sibling.klass.reflect_on_all_associations.select do |assoc|
            assoc.source == attribute
          end
        end.flatten
      end

      def inverse
        @inverse ||=
          through_association ? through_association.inverse : find_inverse
      end

      def inverse_of
        @inverse_of ||= inverse.attribute
      end

      def find_inverse
        klass.reflect_on_all_associations.each do |association|
          next if association.association_foreign_key != @association_foreign_key
          next if association.klass != @owner_class
          next if association.attribute == attribute
          return association if klass == association.owner_class
        end
        raise "Association #{@owner_class}.#{attribute} "\
              "(foreign_key: #{@association_foreign_key}) "\
              "has no inverse in #{@klass_name}"
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
