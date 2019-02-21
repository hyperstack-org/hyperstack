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
      attr_reader :source_type
      attr_reader :options

      def initialize(owner_class, macro, name, options = {})
        owner_class.reflect_on_all_associations << self
        @owner_class = owner_class
        @macro =       macro
        @options =     options
        unless options[:polymorphic]
          @klass_name = options[:class_name] || (collection? && name.camelize.singularize) || name.camelize
        end
        @association_foreign_key =
          options[:foreign_key] ||
          (macro == :belongs_to && "#{name}_id") ||
          (options[:as] && "#{options[:as]}_id") ||
          (options[:polymorphic] && "#{name}_id") ||
          "#{@owner_class.name.underscore}_id"
        if options[:through]
          @source = options[:source] || @klass_name.underscore
          @source_type = options[:source_type] || @klass_name
        end
        @attribute = name
        @through_associations = Hash.new { |_h, k| [] unless k }
        @source_associations =  Hash.new { |_h, k| [] unless k }
      end

      def collection?
        @macro == :has_many
      end

      def singular?
        @macro != :has_many
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

      def through_associations(model)
        # find all associations that use the inverse association as the through association
        # that is find all associations that are using this association in a through relationship
        the_klass = klass(model)
        @through_associations[the_klass] ||= the_klass.reflect_on_all_associations.select do |assoc|
          assoc.through_association && assoc.inverse(nil) == self
        end
      end

      def source_associations(model)
        # find all associations that use this association as the source
        # that is find all associations that are using this association as the source in a
        # through relationship
        the_klass = klass(model)
        @source_associations[the_klass] ||= owner_class.reflect_on_all_associations.collect do |sibling|
          sibling.klass(model).reflect_on_all_associations.select do |assoc|
            assoc.source == attribute && assoc.source_type == the_klass.name
          end
        end.flatten
      end

      def polymorphic?
        !@klass_name
      end

      def inverse(model)
        return @inverse if @inverse
        ta = through_association(model)
        found = ta ? ta.inverse(model) : find_inverse(model)
        @inverse = found unless polymorphic?
        found
      end

      def inverse_of(model = nil)
        inverse(model).attribute
      end

      def find_inverse(model)  # private
        the_klass = klass(model)
        the_klass.reflect_on_all_associations.each do |association|
          next if association.association_foreign_key != @association_foreign_key
          next if association.attribute == attribute
          return association if the_klass == association.owner_class
        end
        debugger if options[:polymorphic]
        raise "could not find inverse of polymorphic belongs_to: #{model.inspect} #{self.inspect}" if options[:polymorphic]
        # instead of raising an error go ahead and create the inverse relationship if it does not exist.
        # https://github.com/hyperstack-org/hyperstack/issues/89
        if macro == :belongs_to
          Hyperstack::Component::IsomorphicHelpers.log "**** warning dynamically adding relationship: #{the_klass}.has_many :#{@owner_class.name.underscore.pluralize}, foreign_key: #{@association_foreign_key}", :warning
          the_klass.has_many @owner_class.name.underscore.pluralize, foreign_key: @association_foreign_key
        elsif options[:as]
          Hyperstack::Component::IsomorphicHelpers.log "**** warning dynamically adding relationship: #{the_klass}.belongs_to :#{options[:as]}, polymorphic: true", :warning
          the_klass.belongs_to options[:as], polymorphic: true
        else
          Hyperstack::Component::IsomorphicHelpers.log "**** warning dynamically adding relationship: #{the_klass}.belongs_to :#{@owner_class.name.underscore}, foreign_key: #{@association_foreign_key}", :warning
          the_klass.belongs_to @owner_class.name.underscore, foreign_key: @association_foreign_key
        end
      end

      def klass(model = nil)
        @klass ||= Object.const_get(@klass_name) if @klass_name
        raise "model is not correct class" if @klass && model && model.class != @klass
        debugger unless @klass || model
        raise "no model supplied for polymorphic relationship" unless @klass || model
        @klass || model.class
      end

      def collection?
        [:has_many].include? @macro
      end
    end
  end
end
