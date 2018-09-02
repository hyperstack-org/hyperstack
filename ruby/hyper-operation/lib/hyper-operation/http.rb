module Hyperloop
  # {HTTP} is used to perform a `XMLHttpRequest` in ruby. It is a simple wrapper
  # around `XMLHttpRequest`
  #
  # # Making requests
  #
  # To create a simple request, {HTTP} exposes class level methods to specify
  # the HTTP action you wish to perform. Each action accepts the url for the
  # request, as well as optional arguments passed as a hash:
  #
  #     HTTP.get("/users/1.json")
  #     HTTP.post("/users", payload: data)
  #
  # The supported `HTTP` actions are:
  #
  # * {HTTP.get}
  # * {HTTP.post}
  # * {HTTP.put}
  # * {HTTP.delete}
  # * {HTTP.patch}
  # * {HTTP.head}
  #
  # # Handling responses
  #
  # Responses can be handled using either a simple block callback, or using a
  # {Promise} returned by the request.
  #
  # ## Using a block
  #
  # All HTTP action methods accept a block which can be used as a simple
  # handler for the request. The block will be called for both successful as well
  # as unsuccessful requests.
  #
  #     HTTP.get("/users/1") do |request|
  #       puts "the request has completed!"
  #     end
  #
  # This `request` object will simply be the instance of the {HTTP} class which
  # wraps the native `XMLHttpRequest`. {HTTP#ok?} can be used to quickly determine
  # if the request was successful.
  #
  #     HTTP.get("/users/1") do |request|
  #       if request.ok?
  #         puts "request was success"
  #       else
  #         puts "something went wrong with request"
  #       end
  #     end
  #
  # The {HTTP} instance will always be the only object passed to the block.
  #
  # ## Using a Promise
  #
  # If no block is given to one of the action methods, then a {Promise} is
  # returned instead. See the standard library for more information on Promises.
  #
  #     HTTP.get("/users/1").then do |req|
  #       puts "response ok!"
  #     end.fail do |req|
  #       puts "response was not ok"
  #     end
  #
  # When using a {Promise}, both success and failure handlers will be passed the
  # {HTTP} instance.
  #
  # # Accessing Response Data
  #
  # All data returned from an HTTP request can be accessed via the {HTTP} object
  # passed into the block or promise handlers.
  #
  # - {#ok?} - returns `true` or `false`, if request was a success (or not).
  # - {#body} - returns the raw text response of the request
  # - {#status_code} - returns the raw {HTTP} status code as integer
  # - {#json} - tries to convert the body response into a JSON object
  class HTTP
    # All valid {HTTP} action methods this class accepts.
    #
    # @see HTTP.get
    # @see HTTP.post
    # @see HTTP.put
    # @see HTTP.delete
    # @see HTTP.patch
    # @see HTTP.head
    ACTIONS = %w[get post put delete patch head]

    # @!method self.get(url, options = {}, &block)
    #
    # Create a {HTTP} `get` request.
    #
    # @example
    #   HTTP.get("/foo") do |req|
    #     puts "got data: #{req.data}"
    #   end
    #
    # @param url [String] url for request
    # @param options [Hash] any request options
    # @yield [self] optional block to handle response
    # @return [Promise, nil] optionally returns a promise

    # @!method self.post(url, options = {}, &block)
    #
    # Create a {HTTP} `post` request. Post data can be supplied using the
    # `payload` options. Usually this will be a hash which will get serialized
    # into a native javascript object.
    #
    # @example
    #   HTTP.post("/bar", payload: data) do |req|
    #     puts "got response"
    #   end
    #
    # @param url [String] url for request
    # @param options [Hash] optional request options
    # @yield [self] optional block to yield for response
    # @return [Promise, nil] returns a {Promise} unless block given

    # @!method self.put(url, options = {}, &block)

    # @!method self.delete(url, options = {}, &block)

    # @!method self.patch(url, options = {}, &block)

    # @!method self.head(url, options = {}, &block)

    ACTIONS.each do |action|
      define_singleton_method(action) do |url, options = {}, &block|
        new.send(action, url, options, block)
      end

      define_method(action) do |url, options = {}, &block|
        send(action, url, options, block)
      end
    end

    attr_reader :body, :error_message, :method, :status_code, :url, :xhr

    def initialize
      @ok = true
    end

    def self.active?
      jquery_active_requests = 0
      %x{
        if (typeof jQuery !== "undefined" && typeof jQuery.active !== "undefined" && jQuery.active !== null) {
          jquery_active_requests = jQuery.active;
        }
      }
      (jquery_active_requests + @active_requests) > 0
    end

    def self.active_requests
      @active_requests ||= 0
      @active_requests
    end

    def self.incr_active_requests
      @active_requests ||= 0
      @active_requests += 1
    end

    def self.decr_active_requests
      @active_requests ||= 0
      @active_requests -= 1
      if @active_requests < 0
        `console.log("Ooops, Hyperloop::HTTP active_requests out of sync!")`
        @active_requests = 0
      end
    end

    def send(method, url, options, block)
      @method   = method
      @url      = url
      @payload  = options.delete :payload
      @handler  = block
      %x{
        var payload_to_send = null;
        var content_type = null;
        if (typeof(this.payload) === 'string') {
          payload_to_send = this.payload;
        }
        else if (this.payload != nil) {
          payload_to_send = this.payload.$to_json();
          content_type = 'application/json';
        }

        var xhr = new XMLHttpRequest();

        xhr.onreadystatechange = function() {
          if(xhr.readyState === XMLHttpRequest.DONE) {
            self.$class().$decr_active_requests();
            if ((xhr.status >= 200 && xhr.status < 300) || xhr.status == 304) {
              return #{succeed(`xhr.responseText`, `xhr.status`, `xhr`)};
            } else {
              return #{fail(`xhr`, `xhr.status`, `xhr.statusText`)};
            }
          }
        }
        xhr.open(this.method.toUpperCase(), this.url);
        if (payload_to_send !== null && content_type !== null) {
          xhr.setRequestHeader("Content-Type", content_type);
        }
        if (options["$has_key?"]("headers")) {
          var headers = options['$[]']("headers");
          var keys = headers.$keys();
          var keys_length = keys.length;
          for (var i=0; i < keys_length; i++) {
            xhr.setRequestHeader( keys[i], headers['$[]'](keys[i]) );
          }
        }
        if (payload_to_send !== null) {
          self.$class().$incr_active_requests();
          xhr.send(payload_to_send);
        } else {
          self.$class().$incr_active_requests();
          xhr.send();
        }
      }

      @handler ? self : promise
    end

    # Parses the http response body through json. If the response is not
    # valid JSON then an error will very likely be thrown.
    #
    # @example Getting JSON content
    #   HTTP.get("api.json") do |response|
    #     puts response.json
    #   end
    #
    #   # => {"key" => 1, "bar" => 2, ... }
    #
    # @return [Hash, Array] returns the parsed json
    def json
      @json ||= JSON.parse(@body)
    end

    # Returns true if the request succeeded, false otherwise.
    #
    # @example
    #   HTTP.get("/some/url") do |response|
    #     if response.ok?
    #       alert "Yay!"
    #     else
    #       alert "Aww :("
    #     end
    #
    # @return [true, false] true if request was successful
    def ok?
      @ok
    end

    # Returns the value of the specified response header.
    #
    # @param key [String] name of the header to get
    # @return [String] value of the header
    # @return [nil] if the header +key+ was not in the response
    def get_header(key)
      %x{
        var value = #@xhr.getResponseHeader(#{key});
        return (value === null) ? nil : value;
      }
    end

    def inspect
      "#<HTTP @url=#{@url} @method=#{@method}>"
    end

    private

    def promise
      return @promise if @promise

      @promise = Promise.new.tap { |promise|
        @handler = proc { |res|
          if res.ok?
            promise.resolve res
          else
            promise.reject res
          end
        }
      }
    end

    def succeed(data, status, xhr)
      %x{
        #@body = data;
        #@xhr  = xhr;
        #@status_code = xhr.status;

        if (typeof(data) === 'object') {
          #@json = #{ JSON.from_object `data` };
        }
      }

      @handler.call self if @handler
    end

    def fail(xhr, status, error)
      %x{
        #@body = xhr.responseText;
        #@xhr = xhr;
        #@status_code = xhr.status;
      }

      @ok = false
      @handler.call self if @handler
    end
  end

end
