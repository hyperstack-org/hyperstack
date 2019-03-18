module ReactiveRecord
  class DummyPolymorph
    def initialize(vector)
      @vector = vector
      puts "VECTOR: #{@vector.inspect}"
      Base.load_from_db(nil, *vector, 'id')
      Base.load_from_db(nil, *vector, 'model_name')
    end

    def nil?
      true
    end

    def method_missing(*)
      self
    end

    def self.reflect_on_all_associations(*)
      []
    end
  end
end
