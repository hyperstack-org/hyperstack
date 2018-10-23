require 'websocket'
require 'socket'
require 'fiber'
require 'listen'
require 'optparse'
require 'json'
require 'pry'

module Hyperstack
  class HotLoader
    # Most of this lifted from https://github.com/saward/Rubame
    class Server

      attr_reader :directories
      def initialize(options)
        Socket.do_not_reverse_lookup
        @hostname = '0.0.0.0'
        @port = options[:port]
        setup_directories(options)

        @reading = []
        @writing = []

        @clients = {} # Socket as key, and Client as value

        @socket = TCPServer.new(@hostname, @port)
        @reading.push @socket
      end

      # adds known directories automatically if they exist
      # - rails js app/assets/javascripts app/assets/stylesheets
      # - reactrb rails defaults app/views/components
      # - you tell me and I'll add them
      def setup_directories(options)
        @directories = options[:directories] || []
        [
          'app/assets/javascripts',
          'app/assets/stylesheets',
          'app/views/components'
        ].each { |known_dir|
          if !@directories.include?(known_dir) && File.exists?(known_dir)
            @directories << known_dir
          end
        }
      end

      def accept
        socket = @socket.accept_nonblock
        @reading.push socket
        handshake = WebSocket::Handshake::Server.new
        client = Client.new(socket, handshake, self)

        while line = socket.gets
          client.handshake << line
          break if client.handshake.finished?
        end
        if client.handshake.valid?
          @clients[socket] = client
          client.write handshake.to_s
          client.opened = true
          return client
        else
          close(client)
        end
        return nil
      end

      def send_updated_file(modified_file)
        if modified_file =~ /\.rb(\.erb)?$/
          if File.exist?(modified_file)
            file_contents = File.read(modified_file).force_encoding(Encoding::UTF_8)
          end
          relative_path = Pathname.new(modified_file).relative_path_from(Pathname.new(Dir.pwd)).to_s
          asset_path = nil
          @directories.each do |directory|
            next unless relative_path =~ /^#{directory}/
            asset_path = relative_path.gsub("#{directory}/", '')
          end
          update = {
            type: 'ruby',
            filename: modified_file,
            asset_path: asset_path,
            source_code: file_contents || ''
          }.to_json
        end
        if modified_file =~ /\.s?[ac]ss$/ && File.exist?(modified_file)
          # Don't know how to remove css definitions at the moment
          # TODO: Switch from hard-wired path assumptions to using SASS/sprockets config
          relative_path = Pathname.new(modified_file).relative_path_from(Pathname.new(Dir.pwd))
          url = relative_path.to_s
            .sub('public/','')
            .sub('/sass/','/')
            .sub(/\.s[ac]ss/, '.css')
          update = {
            type: 'css',
            filename: modified_file,
            url: url
          }.to_json
        end
        if update
          @clients.each { |socket, client| client.send(update) }
        end
      end

      PROGRAM = 'opal-hot-reloader'
      def loop
        listener = Listen.to(*@directories, only: %r{\.(rb(\.erb)?|s?[ac]ss)$}) do |modified, added, removed|
          (removed + modified + added).each { |file| send_updated_file(file) }
          puts "removed absolute path: #{removed}"
          puts "modified absolute path: #{modified}"
          puts "added absolute path: #{added}"
        end
        listener.start

        puts "#{PROGRAM}: starting..."
        while (!$quit)
          run do |client|
            client.onopen do
              puts "#{PROGRAM}:  client open"
            end
            client.onmessage do |mess|
              puts "PROGRAM:  message received: #{mess}" unless mess == ''
            end
            client.onclose do
              puts "#{PROGRAM}:  client closed"
            end
          end
          sleep 0.2
        end
      end

      def read(client)

    pairs = client.socket.recvfrom(2000)
    messages = []

    if pairs[0].length == 0
      close(client)
    else
      client.frame << pairs[0]

      while f = client.frame.next
        if (f.type == :close)
          close(client)
          return messages
        else
          messages.push f
        end
      end

    end

    return messages

  end

  def close(client)
    @reading.delete client.socket
    @clients.delete client.socket
    begin
      client.socket.close
    rescue
    end
    client.closed = true
  end

  def run(time = 0, &blk)
    readable, writable = IO.select(@reading, @writing, nil, 0)

    if readable
      readable.each do |socket|
        client = @clients[socket]
        if socket == @socket
          client = accept
        else
          msg = read(client)
          client.messaged = msg
        end

        blk.call(client) if client and blk
      end
    end

    # Check for lazy send items
    timer_start = Time.now
    time_passed = 0
    begin
      @clients.each do |s, c|
        c.send_some_lazy(5)
      end
      time_passed = Time.now - timer_start
    end while time_passed < time
  end

  def stop
    @socket.close
  end
  end

  class Client
    attr_accessor :socket, :handshake, :frame, :opened, :messaged, :closed

    def initialize(socket, handshake, server)
      @socket = socket
      @handshake = handshake
      @frame = WebSocket::Frame::Incoming::Server.new(:version => @handshake.version)
      @opened = false
      @messaged = []
      @lazy_queue = []
      @lazy_current_queue = nil
      @closed = false
      @server = server
    end

    def write(data)
      @socket.write data
    end

    def send(data)
      frame = WebSocket::Frame::Outgoing::Server.new(:version => @handshake.version, :data => data, :type => :text)
      begin
        @socket.write frame
        @socket.flush
      rescue
        @server.close(self) unless @closed
      end
    end

    def lazy_send(data)
      @lazy_queue.push data
    end

    def get_lazy_fiber
      # Create the fiber if needed
      if @lazy_fiber == nil or !@lazy_fiber.alive?
        @lazy_fiber = Fiber.new do
          @lazy_current_queue.each do |data|
            send(data)
            Fiber.yield unless @lazy_current_queue[-1] == data
          end
        end
      end

      return @lazy_fiber
    end

    def send_some_lazy(count)
      # To save on cpu cycles, we don't want to be chopping and changing arrays, which could get quite large.  Instead,
      # we iterate over an array which we are sure won't change out from underneath us.
      unless @lazy_current_queue
        @lazy_current_queue = @lazy_queue
        @lazy_queue = []
      end

      completed = 0
      begin
        get_lazy_fiber.resume
        completed += 1
      end while (@lazy_queue.count > 0 or @lazy_current_queue.count > 0) and completed < count

    end

    def onopen(&blk)
      if @opened
        begin
          blk.call
        ensure
          @opened = false
        end
      end
    end

    def onmessage(&blk)
      if @messaged.size > 0
        begin
          @messaged.each do |x|
            blk.call(x.to_s)
          end
        ensure
          @messaged = []
        end
      end
    end

    def onclose(&blk)
      if @closed
        begin
          blk.call
        ensure
        end
      end
    end
  end

  line = 0
  end
end
