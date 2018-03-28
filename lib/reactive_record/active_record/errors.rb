require 'active_support/core_ext/string/inflections'

module ActiveModel
  class Errors
    include Enumerable

    CALLBACKS_OPTIONS = [:if, :unless, :on, :allow_nil, :allow_blank, :strict]
    MESSAGE_OPTIONS = [:message]

    attr_reader :messages, :details

    # Pass in the instance of the object that is using the errors object.
    #
    #   class Person
    #     def initialize
    #       @errors = ActiveModel::Errors.new(self)
    #     end
    #   end
    def initialize(base = {})
      @base = base
      @messages = apply_default_array({})
      @details = apply_default_array({})
      reactive_empty! true
    end

    # When passed a symbol or a name of a method, returns an array of errors
    # for the method.
    #
    #   person.errors[:name]  # => ["cannot be nil"]
    #   person.errors['name'] # => ["cannot be nil"]
    def [](attribute)
      messages[attribute]
    end

    # Iterates through each error key, value pair in the error messages hash.
    # Yields the attribute and the error for that attribute. If the attribute
    # has more than one error message, yields once for each error message.
    #
    #   person.errors.add(:name, :blank, message: "can't be blank")
    #   person.errors.each do |attribute, error|
    #     # Will yield :name and "can't be blank"
    #   end
    #
    #   person.errors.add(:name, :not_specified, message: "must be specified")
    #   person.errors.each do |attribute, error|
    #     # Will yield :name and "can't be blank"
    #     # then yield :name and "must be specified"
    #   end
    def each
      messages.each_key do |attribute|
        messages[attribute].each { |error| yield attribute, error }
      end
    end

    # Delete messages for +key+. Returns the deleted messages.
    #
    #   person.errors[:name]        # => ["cannot be nil"]
    #   person.errors.delete(:name) # => ["cannot be nil"]
    #   person.errors[:name]        # => []
    def delete(attribute)
      details.delete(attribute)
      messages.delete(attribute)
    end

    # Returns the number of error messages.
    #
    #   person.errors.add(:name, :blank, message: "can't be blank")
    #   person.errors.size # => 1
    #   person.errors.add(:name, :not_specified, message: "must be specified")
    #   person.errors.size # => 2
    def size
      values.flatten.size
    end
    alias :count :size

    # Returns all message keys.
    #
    #   person.errors.messages # => {:name=>["cannot be nil", "must be specified"]}
    #   person.errors.keys     # => [:name]
    def keys
      messages.select do |key, value|
        !value.empty?
      end.keys
    end

    # Returns all message values.
    #
    #   person.errors.messages # => {:name=>["cannot be nil", "must be specified"]}
    #   person.errors.values   # => [["cannot be nil", "must be specified"]]
    def values
      messages.select do |key, value|
        !value.empty?
      end.values
    end

    # NOTE: Doesn't use i18n
    #
    # Returns a full message for a given attribute.
    #
    #   person.errors.full_message(:name, 'is invalid') # => "Name is invalid"
    def full_message(attribute, message)
      return message if attribute == :base
      # TODO: When opal_activesupport 0.3.2 is released, use `humanize`
      # attr_name = attribute.to_s.tr('.', '_').humanize
      attr_name =
        attribute.to_s.tr('.', '_').tr('_', ' ').gsub(/_id$/, '').capitalize
      # attr_name = @base.class.human_attribute_name(attribute, default: attr_name)
      # if @base.class.respond_to?(:human_attribute_name)
        attr_name = @base.class.human_attribute_name(attribute, default: attr_name)
      # end
      # I18n.t(:"errors.format",
      #   default:  "%{attribute} %{message}",
      #   attribute: attr_name,
      #   message:   message)
      "#{attr_name} #{message}"
    end

    # Returns all the full error messages in an array.
    #
    #   class Person
    #     validates_presence_of :name, :address, :email
    #     validates_length_of :name, in: 5..30
    #   end
    #
    #   person = Person.create(address: '123 First St.')
    #   person.errors.full_messages
    #   # => ["Name is too short (minimum is 5 characters)", "Name can't be blank", "Email can't be blank"]
    def full_messages
      map { |attribute, message| full_message(attribute, message) }
    end
    alias :to_a :full_messages

    # Returns all the full error messages for a given attribute in an array.
    #
    #   class Person
    #     validates_presence_of :name, :email
    #     validates_length_of :name, in: 5..30
    #   end
    #
    #   person = Person.create()
    #   person.errors.full_messages_for(:name)
    #   # => ["Name is too short (minimum is 5 characters)", "Name can't be blank"]
    def full_messages_for(attribute)
      messages[attribute].map { |message| full_message(attribute, message) }
    end

    # Returns a Hash of attributes with their error messages. If +full_messages+
    # is +true+, it will contain full messages (see +full_message+).
    #
    #   person.errors.to_hash       # => {:name=>["cannot be nil"]}
    #   person.errors.to_hash(true) # => {:name=>["name cannot be nil"]}
    def to_hash(full_messages = false)
      if full_messages
        messages.each_with_object({}) do |(attribute, array), messages|
          messages[attribute] = array.map { |message| full_message(attribute, message) }
        end
      else
        without_default_proc(messages)
      end
    end

    # Returns a Hash that can be used as the JSON representation for this
    # object. You can pass the <tt>:full_messages</tt> option. This determines
    # if the json object should contain full messages or not (false by default).
    #
    #   person.errors.as_json                      # => {:name=>["cannot be nil"]}
    #   person.errors.as_json(full_messages: true) # => {:name=>["name cannot be nil"]}
    def as_json(options = nil)
      to_hash(options && options[:full_messages])
    end

    # NOTE: Doesn't actually do any of the below i18n lookups
    #
    # Translates an error message in its default scope
    # (<tt>activemodel.errors.messages</tt>).
    #
    # Error messages are first looked up in <tt>activemodel.errors.models.MODEL.attributes.ATTRIBUTE.MESSAGE</tt>,
    # if it's not there, it's looked up in <tt>activemodel.errors.models.MODEL.MESSAGE</tt> and if
    # that is not there also, it returns the translation of the default message
    # (e.g. <tt>activemodel.errors.messages.MESSAGE</tt>). The translated model
    # name, translated attribute name and the value are available for
    # interpolation.
    #
    # When using inheritance in your models, it will check all the inherited
    # models too, but only if the model itself hasn't been found. Say you have
    # <tt>class Admin < User; end</tt> and you wanted the translation for
    # the <tt>:blank</tt> error message for the <tt>title</tt> attribute,
    # it looks for these translations:
    #
    # * <tt>activemodel.errors.models.admin.attributes.title.blank</tt>
    # * <tt>activemodel.errors.models.admin.blank</tt>
    # * <tt>activemodel.errors.models.user.attributes.title.blank</tt>
    # * <tt>activemodel.errors.models.user.blank</tt>
    # * any default you provided through the +options+ hash (in the <tt>activemodel.errors</tt> scope)
    # * <tt>activemodel.errors.messages.blank</tt>
    # * <tt>errors.attributes.title.blank</tt>
    # * <tt>errors.messages.blank</tt>
    def generate_message(attribute, type = :invalid, options = {})
      options.delete(:message) || type
    end

    # Returns +true+ if no errors are found, +false+ otherwise.
    # If the error message is a string it can be empty.
    #
    #   person.errors.full_messages # => ["name cannot be nil"]
    #   person.errors.empty?        # => false
    def empty?
      size.zero?
    end
    alias :blank? :empty?

    def reactive_empty?
      React::State.get_state(self, 'ERRORS?')
    end

    # Clear the error messages.
    #
    #   person.errors.full_messages # => ["name cannot be nil"]
    #   person.errors.clear
    #   person.errors.full_messages # => []
    def clear
      messages.clear
      details.clear.tap { reactive_empty! true }
    end

    # Merges the errors from <tt>other</tt>.
    #
    # other - The ActiveModel::Errors instance.
    #
    # Examples
    #
    #   person.errors.merge!(other)
    def merge!(other)
      @messages.merge!(other.messages) { |_, ary1, ary2| ary1 + ary2 }
      @details.merge!(other.details) { |_, ary1, ary2| ary1 + ary2 }.tap { reactive_empty! }
    end

    # Returns +true+ if the error messages include an error for the given key
    # +attribute+, +false+ otherwise.
    #
    #   person.errors.messages        # => {:name=>["cannot be nil"]}
    #   person.errors.include?(:name) # => true
    #   person.errors.include?(:age)  # => false
    def include?(attribute)
      attribute = attribute.to_sym
      messages.key?(attribute) && messages[attribute].present?
    end
    alias :has_key? :include?
    alias :key? :include?

    # NOTE: strict option isn't ported yet
    #
    # Adds +message+ to the error messages and used validator type to +details+ on +attribute+.
    # More than one error can be added to the same +attribute+.
    # If no +message+ is supplied, <tt>:invalid</tt> is assumed.
    #
    #   person.errors.add(:name)
    #   # => ["is invalid"]
    #   person.errors.add(:name, :not_implemented, message: "must be implemented")
    #   # => ["is invalid", "must be implemented"]
    #
    #   person.errors.messages
    #   # => {:name=>["is invalid", "must be implemented"]}
    #
    #   person.errors.details
    #   # => {:name=>[{error: :not_implemented}, {error: :invalid}]}
    #
    # If +message+ is a symbol, it will be translated using the appropriate
    # scope (see +generate_message+).
    #
    # If +message+ is a proc, it will be called, allowing for things like
    # <tt>Time.now</tt> to be used within an error.
    #
    # If the <tt>:strict</tt> option is set to +true+, it will raise
    # ActiveModel::StrictValidationFailed instead of adding the error.
    # <tt>:strict</tt> option can also be set to any other exception.
    #
    #   person.errors.add(:name, :invalid, strict: true)
    #   # => ActiveModel::StrictValidationFailed: Name is invalid
    #   person.errors.add(:name, :invalid, strict: NameIsInvalid)
    #   # => NameIsInvalid: Name is invalid
    #
    #   person.errors.messages # => {}
    #
    # +attribute+ should be set to <tt>:base</tt> if the error is not
    # directly associated with a single attribute.
    #
    #   person.errors.add(:base, :name_or_email_blank,
    #     message: "either name or email must be present")
    #   person.errors.messages
    #   # => {:base=>["either name or email must be present"]}
    #   person.errors.details
    #   # => {:base=>[{error: :name_or_email_blank}]}
    def add(attribute, message = :invalid, options = {})
      message = message.call if message.respond_to?(:call)
      detail  = normalize_detail(message, options)
      message = normalize_message(attribute, message, options)
      # if exception = options[:strict]
      #   exception = ActiveModel::StrictValidationFailed if exception == true
      #   raise exception, full_message(attribute, message)
      # end
      details[attribute.to_sym]  << detail
      (messages[attribute.to_sym] << message).tap { reactive_empty! false }
    end

    # NOTE: Due to Opal not supporting Symbol this isn't identical,
    # but probably still works fine in most cases.
    #
    # Returns +true+ if an error on the attribute with the given message is
    # present, or +false+ otherwise. +message+ is treated the same as for +add+.
    #
    #   person.errors.add :name, :blank
    #   person.errors.added? :name, :blank           # => true
    #   person.errors.added? :name, "can't be blank" # => true
    #
    # If the error message requires an option, then it returns +true+ with
    # the correct option, or +false+ with an incorrect or missing option.
    #
    #  person.errors.add :name, :too_long, { count: 25 }
    #  person.errors.added? :name, :too_long, count: 25                     # => true
    #  person.errors.added? :name, "is too long (maximum is 25 characters)" # => true
    #  person.errors.added? :name, :too_long, count: 24                     # => false
    #  person.errors.added? :name, :too_long                                # => false
    #  person.errors.added? :name, "is too long"                            # => false
    def added?(attribute, message = :invalid, options = {})
      # if message.is_a? Symbol
      #   self.details[attribute].map { |e| e[:error] }.include? message
      # else
      #   message = message.call if message.respond_to?(:call)
      #   message = normalize_message(attribute, message, options)
      #   self[attribute].include? message
      # end
      return true if details[attribute].map { |e| e[:error] }.include? message
      message = message.call if message.respond_to?(:call)
      message = normalize_message(attribute, message, options)
      self[attribute].include? message
    end

    private

    def apply_default_array(hash)
      hash.default_proc = proc { |h, key| h[key] = [] }
      hash
    end

    def normalize_message(attribute, message, options)
      # case message
      # when Symbol
      #   generate_message(attribute, message, options.except(*CALLBACKS_OPTIONS))
      # else
      #   message
      # end
      generate_message(
        attribute, message, options.reject { |k, _| CALLBACKS_OPTIONS.include?(k) }
      )
    end

    def normalize_detail(message, options)
      # { error: message }.merge(options.except(*CALLBACKS_OPTIONS + MESSAGE_OPTIONS))
      ignore = (CALLBACKS_OPTIONS + MESSAGE_OPTIONS)
      { error: message }.merge(options.reject { |k, _| ignore.include?(k) })
    end

    def without_default_proc(hash)
      hash.dup.tap do |new_h|
        new_h.default_proc = nil
      end
    end

    def reactive_empty!(state = empty?)
      React::State.set_state(self, 'ERRORS?', state) unless ReactiveRecord::Base.data_loading?
    end
  end
end
