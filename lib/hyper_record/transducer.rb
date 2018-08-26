module HyperRecord
  class Transducer
    def self.collection_query(request)
      fetch(request)
    end

    def self.destroy(request)
      { destroy: request }
    end

    def self.fetch(request)
      { fetch: request }
    end

    def self.find(request)
      fetch(request)
    end

    def self.find_by(request)
      fetch(request)
    end

    def self.link(request)
      { link: request }
    end

    def self.relation(request)
      fetch(request)
    end

    def self.save(request)
      { save: request }
    end

    def self.unlink(request)
      { unlink: request }
    end

    def self.where(request)
      fetch(request)
    end
  end
end