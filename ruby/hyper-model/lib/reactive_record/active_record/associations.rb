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
      attr_reader :polymorphic_type_attribute

      def initialize(owner_class, macro, name, options = {})
        owner_class.reflect_on_all_associations << self
        @owner_class = owner_class
        @macro =       macro
        @options =     options
        unless options[:polymorphic]
          @klass_name = options[:class_name] || (collection? && name.camelize.singularize) || name.camelize
        end

        if @klass_name < ActiveRecord::Base
          @klass = @klass_name
          @klass_name = @klass_name.name
        end rescue nil

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
        @polymorphic_type_attribute = "#{name}_type" if options[:polymorphic]
        @attribute = name
        @through_associations = Hash.new { |_h, k| [] unless k }
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

      # class Membership < ActiveRecord::Base
      #   belongs_to :uzer
      #   belongs_to :memerable, polymorphic: true
      # end
      #
      # class Project < ActiveRecord::Base
      #   has_many :memberships, as: :memerable, dependent: :destroy
      #   has_many :uzers, through: :memberships
      # end
      #
      # class Group < ActiveRecord::Base
      #   has_many :memberships, as: :memerable, dependent: :destroy
      #   has_many :uzers, through: :memberships
      # end
      #
      # class Uzer < ActiveRecord::Base
      #   has_many :memberships
      #   has_many :groups,   through: :memberships, source: :memerable, source_type: 'Group'
      #   has_many :projects, through: :memberships, source: :memerable, source_type: 'Project'
      # end

      # so find the belongs_to relationship whose attribute == ta.source
      # now find the inverse of that relationship using source_value as the model
      # now find any has many through relationships that use that relationship as there source.
      # each of those attributes in the source_value have to be updated.

      # self is the through association


      def through_associations(model)
        # given self is a belongs_to association currently pointing to model
        # find all associations that use the inverse association as the through association
        # that is find all associations that are using this association in a through relationship
        the_klass = klass(model)
        @through_associations[the_klass] ||= the_klass.reflect_on_all_associations.select do |assoc|
          assoc.through_association&.inverse == self
        end
      end

      def source_belongs_to_association  # private
        # given self is a has_many_through association return the corresponding belongs_to association
        # for the source
        @source_belongs_to_association ||=
          through_association.inverse.owner_class.reflect_on_all_associations.detect do |sibling|
            sibling.attribute == source
          end
      end

      def source_associations(model)
        # given self is a has_many_through association find the source_association for the given model
        source_belongs_to_association.through_associations(model)
      end

      alias :polymorphic? polymorphic_type_attribute

      def inverse(model = nil)
        return @inverse if @inverse
        ta = through_association
        found = ta ? ta.inverse : find_inverse(model)
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
          return association if association.polymorphic? || association.klass == owner_class
        end
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
        if @klass && model && !(model.class <= @klass || @klass <= model.class)
          # TODO: added || @klass <= model.class can both cases really happen I guess so
          raise "internal error: provided model #{model} is not subclass of #{@klass}"
        end
        raise 'no model supplied for polymorphic relationship' unless @klass || model
        @klass || model.class
      end

      def collection?
        [:has_many].include? @macro
      end

      def remove_member(member, owner)
        collection = owner.attributes[attribute]
        return if collection.nil?
        collection.delete(member)
      end

      def add_member(member, owner)
        owner.attributes[attribute] ||= ReactiveRecord::Collection.new(member.class, owner, self)
        owner.attributes[attribute]._internal_push member
      end
    end
  end
end
