module ReactiveRecord
  # ActiveRecord column access and conversion helpers
  class Base
    def columns_hash
      model.columns_hash
    end

    def self.column_type(column_hash)
      column_hash && column_hash[:sql_type_metadata] && column_hash[:sql_type_metadata][:type]
    end

    def column_type(attr)
      Base.column_type(columns_hash[attr])
    end

    def convert_datetime(val)
      if val.is_a?(Numeric)
        Time.at(val)
      elsif val.is_a?(Time)
        val
      else
        Time.parse(val)
      end
    end

    alias convert_time convert_datetime
    alias convert_timestamp convert_datetime

    def convert_date(val)
      if val.is_a?(Time)
        Date.parse(val.strftime('%d/%m/%Y'))
      elsif val.is_a?(Date)
        val
      else
        Date.parse(val)
      end
    end

    def convert_boolean(val)
      !['false', false, nil, 0].include?(val)
    end

    def convert_integer(val)
      Integer(`parseInt(#{val})`)
    end

    alias convert_bigint convert_integer

    def convert_float(val)
      Float(val)
    end

    alias convert_decimal convert_float

    def convert_text(val)
      val.to_s
    end

    alias convert_string convert_text

    def self.serialized?
      @serialized_attrs ||= Hash.new { |h, k| h[k] = Hash.new }
    end

    def convert(attr, val)
      column_type = column_type(attr)
      return val if self.class.serialized?[model][attr] ||
                    !column_type || val.loading? ||
                    (!val && column_type != :boolean)
      conversion_method = "convert_#{column_type}"
      return send(conversion_method, val) if respond_to? conversion_method
      val
    end
  end
end
