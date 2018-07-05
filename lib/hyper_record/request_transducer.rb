module HyperRecord
  class RequestTransducer
    def destroy(request)
      { destroy: request }
    end

    def fetch(request)
      { fetch: request }
    end

    def link(request)
      { link: request }
    end

    def save(request)
      { save: request }
    end

    def unlink(request)
      { unlink: request }
    end
  end
end