module Hyperloop
  module Transport
    # HTTP is used to perform a `XMLHttpRequest` in ruby. It is a simple wrapper
    # around `XMLHttpRequest`
    #
    # # Making requests
    #
    # To create a simple request, HTTP exposes class level methods to specify
    # the HTTP action you wish to perform. Each action accepts the url for the
    # request, as well as optional arguments passed as a hash:
    #
    #     HTTP.get("/users/1.json")
    #     HTTP.post("/users", payload: data)
    #
    # The supported `HTTP` actions are:
    #
    # * HTTP.get
    # * HTTP.post
    # * HTTP.put
    # * HTTP.delete
    # * HTTP.patch
    # * HTTP.head
    #
    # # Handling responses
    #
    # Responses can be handled using a Promise returned by the request.
    #
    # ## Using a Promise
    #
    # If no block is given to one of the action methods, then a Promise is
    # returned instead. See the standard library for more information on Promises.
    #
    #     HTTP.get("/users/1").then do |req|
    #       puts "response ok!"
    #     end.fail do |req|
    #       puts "response was not ok"
    #     end
    #
    # When using a Promise, both success and failure handlers will be passed the
    # HTTP instance.
    #
    # # Accessing Response Data
    #
    # All data returned from an HTTP request can be accessed via the HTTP object
    # passed into the block or promise handlers.
    #
    # - #ok? - returns `true` or `false`, if request was a success (or not).
    # - #body - returns the raw text response of the request
    # - #status_code - returns the raw {HTTP} status code as integer
    # - #json - tries to convert the body response into a JSON object
    class HTTP
      # All valid HTTP action methods this class accepts.
      #
      # @see HTTP.get
      # @see HTTP.post
      # @see HTTP.put
      # @see HTTP.delete
      # @see HTTP.patch
      # @see HTTP.head
      ACTIONS = %w[get post put delete patch head]

      # @!method self.get(url, options = {})
      #
      # Create a {HTTP} `get` request.
      #
      # @example
      #   HTTP.get("/foo").then do |req|
      #     puts "got data: #{req.data}"
      #   end
      #
      # @param url [String] url for request
      # @param options [Hash] any request options
      # @return [Promise] returns a promise

      # @!method self.post(url, options = {})
      #
      # Create a {HTTP} `post` request. Post data can be supplied using the
      # `payload` options. Usually this will be a hash which will get serialized
      # into a native javascript object.
      #
      # @example
      #   HTTP.post("/bar", payload: data).then do |req|
      #     puts "got response"
      #   end
      #
      # @param url [String] url for request
      # @param options [Hash] optional request options
      # @return [Promise] returns a Promise

      # @!method self.put(url, options = {})

      # @!method self.delete(url, options = {})

      # @!method self.patch(url, options = {})

      # @!method self.head(url, options = {})

      ACTIONS.each do |action|
        define_singleton_method(action) do |url, options = {}|
          new.send(action, url, options)
        end

        define_method(action) do |url, options = {}|
          send(action, url, options)
        end
      end

      attr_reader :body, :error_message, :method, :status_code, :url, :xhr

      def initialize
        @ok = true
      end

      # check if requests are still active
      # return [Boolean]
      def self.active?
        @active_requests > 0
      end

      # @private
      def self.active_requests
        @active_requests ||= 0
        @active_requests
      end

      # @private
      def self.incr_active_requests
        @active_requests ||= 0
        @active_requests += 1
      end

      # @private
      def self.decr_active_requests
        @active_requests ||= 0
        @active_requests -= 1
        if @active_requests < 0
          `console.warn("Ooops, Hyperloop::HTTP active_requests out of sync!")`
          @active_requests = 0
        end
      end

      # @private
      def send(method, url, options)
        @method   = method
        @url      = url
        @payload  = options.delete :payload
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
          var csrf_elements = document.getElementsByName("csrf-token");

          xhr.onreadystatechange = function() {
            if(xhr.readyState === XMLHttpRequest.DONE) {
              self.$class().$decr_active_requests();
              if ((xhr.status >= 200 && xhr.status < 300) || xhr.status == 304) {
                return #{succeed(`xhr`, `xhr.status`, `xhr.responseText`)};
              } else {
                return #{fail(`xhr`, `xhr.status`, `xhr.statusText`)};
              }
            }
          }
          xhr.open(this.method.toUpperCase(), this.url);
          if (csrf_elements.length > 0) {
            xhr.setRequestHeader("X-CSRF-Token", csrf_elements[0]["content"]);
          }
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

        promise
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

      # inspect on request
      # @return [String]
      def inspect
        "#<HTTP @url=#{@url} @method=#{@method}>"
      end

      # meant for hyper-resource
      def self.promise_send(uri, data)
        post(uri + "?timestamp=#{`Date.now() + Math.random()`}", payload: data).then do |response|
          Hyperloop::Transport::ResponseProcessor.process_response(response.json)
        end
      end

      private

      # @private
      def promise
        return @promise if @promise

        @promise = Promise.new
      end

      # @private
      def succeed(xhr, status, data)
        %x{
          #@body = data;
          #@xhr  = xhr;
          #@status_code = xhr.status;

          if (typeof(data) === 'object') {
            #@json = #{ JSON.from_object(`data`) };
          }
        }

        @promise.resolve(self)
      end

      # @private
      def fail(xhr, status, error)
        %x{
          #@body = xhr.responseText;
          #@xhr = xhr;
          #@status_code = xhr.status;
        }

        @ok = false
        @promise.reject(self)
      end
    end
  end
end
