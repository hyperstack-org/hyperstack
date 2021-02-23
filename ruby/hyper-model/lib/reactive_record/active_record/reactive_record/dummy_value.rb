# add methods to Object to determine if this is a dummy object or not
class Object
  def loaded?
    !loading?
  end

  def loading?
    false
  end
end

module ReactiveRecord
  class Base
    # A DummyValue stands in for actual value while waiting for load from
    # server.  when value is accessed by most methods it notifies hyper-react
    # so when the actual value loads react will update.

    # DummyValue uses the ActiveRecord type info to act like an appropriate
    # loaded value.
    class DummyValue < BasicObject
      def initialize(column_hash = nil)
        column_hash ||= {}
        notify
        @column_hash = column_hash
        column_type = Base.column_type(@column_hash) || 'nil'
        default_value_method = "build_default_value_for_#{column_type}"
        @object = __send__ default_value_method
      rescue ::Exception
      end

      def build_default_value_for_nil
        @column_hash[:default] || nil
      end

      def build_default_value_for_json
        ::JSON.parse(@column_hash[:default]) if @column_hash[:default]
      end

      alias build_default_value_for_jsonb build_default_value_for_json

      def build_default_value_for_datetime
        if @column_hash[:default]
          ::Time.parse(@column_hash[:default].gsub(' ','T')+'+00:00')
        else
          ::ReactiveRecord::Base::DummyValue.dummy_time
        end
      end

      alias build_default_value_for_time build_default_value_for_datetime
      alias build_default_value_for_timestamp build_default_value_for_datetime

      def build_default_value_for_date
        if @column_hash[:default]
          ::Date.parse(@column_hash[:default])
        else
          ::ReactiveRecord::Base::DummyValue.dummy_date
        end
      end

      FALSY_VALUES = [false, nil, 0, "0", "f", "F", "false", "FALSE", "off", "OFF"]

      def build_default_value_for_boolean
        !FALSY_VALUES.include?(@column_hash[:default])
      end

      def build_default_value_for_float
        @column_hash[:default]&.to_f || Float(0.0)
      end

      alias build_default_value_for_decimal build_default_value_for_float

      def build_default_value_for_integer
        @column_hash[:default]&.to_i || Integer(0)
      end

      alias build_default_value_for_bigint build_default_value_for_integer

      def build_default_value_for_string
        return @column_hash[:default] if @column_hash[:serialized?]
        @column_hash[:default] || ''
      end

      alias build_default_value_for_text build_default_value_for_string

      def notify
        return if ::ReactiveRecord::Base.data_loading?
        ::ReactiveRecord.loads_pending!
        ::ReactiveRecord::WhileLoading.loading!
      end

      def loading?
        true
      end

      def loaded?
        false
      end

      def nil?
        true
      end

      def !
        true
      end

      def class
        notify
        @object.class
      end

      def method_missing(method, *args, &block)
        if method.start_with?("build_default_value_for_")
          nil
        elsif @object || @object.respond_to?(method)
          notify
          @object.send method, *args, &block
        elsif 0.respond_to? method
          notify
          0.send(method, *args, &block)
        elsif ''.respond_to? method
          notify
          ''.send(method, *args, &block)
        else
          super
        end
      end

      def coerce(s)
        # notify # why are we not notifying here
        return @object.coerce(s) if @object
        [__send__("to_#{s.class.name.downcase}"), s]
      end

      def ==(other)
        # notify # why are we not notifying here
        other.object_id == object_id
      end

      def object_id
        `self.$$id`
      end

      def is_a?(klass)
        klass == ::ReactiveRecord::Base::DummyValue
      end

      def zero?
        return @object.zero? if @object
        false
      end

      def to_s
        notify
        return @object.to_s if @object
        ''
      end

      def tap
        yield self
        self
      end

      alias inspect to_s

      %x{
        if (Opal.Object.$$proto) {
          #{self}.$$proto.toString = Opal.Object.$$proto.toString
        } else {
          #{self}.$$prototype.toString = Opal.Object.$$prototype.toString
        }
       }

      def to_f
        notify
        return @object.to_f if @object
        0.0
      end

      def to_i
        notify
        return @object.to_i if @object
        0
      end

      def to_numeric
        notify
        return @object.to_numeric if @object
        0
      end

      def to_number
        notify
        return @object.to_number if @object
        0
      end

      def self.dummy_time
        @dummy_time ||= ::Time.parse('2001-01-01T00:00:00.000-00:00')
      end

      def self.dummy_date
        @dummy_date ||= ::Date.parse('1/1/2001')
      end

      def to_date
        notify
        return @object.to_date if @object
        ::ReactiveRecord::Base::DummyValue.dummy_date
      end

      def to_time
        notify
        return @object.to_time if @object
        ::ReactiveRecord::Base::DummyValue.dummy_time
      end

      def acts_as_string?
        return true if @object.is_a? ::String
        return @object.acts_as_string? if @object && @object.respond_to?(:acts_as_string?)
        true
      end

      # this is a hackish way and compatible with any other rendered object
      # to identify a DummyValue during render
      # in ReactRenderingContext.run_child_block() and
      # to convert it to a string, for rendering
      # advantage over a try(:method) is, that it doesnt raise und thus is faster
      # which is important during render
      def respond_to?(method)
        return true if method == :acts_as_string?
        return true if %i[inspect to_date to_f to_i to_numeric to_number to_s to_time].include? method
        return @object.respond_to? if @object
        false
      end

      def try(*args, &b)
        if args.empty? && block_given?
          yield self
        else
          __send__(*args, &b)
        end
      rescue ::Exception
        nil
      end
    end
  end
end
