module HyperRecord
  class Transducer
    def self.destroy(request)
      { destroy: request }
    end

    def self.fetch(request)
      { fetch: request }
    end

    def self.link(request)
      { link: request }
    end

    def self.save(request)
      { save: request }
    end

    def self.unlink(request)
      { unlink: request }
    end
  end
end