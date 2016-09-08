module Synchromesh
  class PolledConnection

    STORE_ID = 'synchromesh-polled-connection-store'

    class << self

      def polled_connections_for(channel: nil, session: nil)
        Enumerator.new do |y|
          new_array = []
          store = PStore.new(STORE_ID)
          store.transaction do
            store[:polled_connections].each do |pc|
              next if pc.timeout < Time.now
              y << pc if (!channel || pc.channel == channel) && (!session || session == pc.session)
              new_array << pc
            end if store[:polled_connections]
            store[:polled_connections] = new_array
          end
        end
      end

      def new(*args)
        super.tap do |pc|
          store = PStore.new(STORE_ID)
          store.transaction do
            store[:polled_connections] ||= []
            store[:polled_connections] << pc
          end
        end
      end

      # save this message for any sessions that care about this channel
      # message[:channel] has the channel this data is being sent to
      def write(message)
        channel = message[1][:channel]
        polled_connections_for(channel: channel).each do |pc|
          pc.write message
        end
      end

      def read(session)
        polled_connections_for(session: session).collect do |pc|
          pc.read_messages
        end.flatten(1)
      end

      # this session-channel pair has now connected to some other transport (or has been removed)
      # set time out and return all the polled messages for the session-chanel pair
      def disconnect(session, channel)
        polled_connections_for(channel: channel, session: session).collect do |polled_connection|
          polled_connection.timeout = Time.at(0)
          polled_connection.messages
        end.flatten(1)
      end

      def open_connections
        polled_connections_for.collect(&:channel).uniq
      end

    end

    attr_accessor :session
    attr_accessor :channel
    attr_accessor :timeout
    attr_accessor :messages

    def write(message)
      @messages << message
    end

    def read_messages
      current_messages = @messages
      @messages = []
      @timeout = Time.now + Synchromesh.seconds_polled_data_will_be_retained
      current_messages
    end

    def initialize(session, channel)
      @session = session
      @channel = channel
      @timeout = Time.now + Synchromesh.autoconnect_timeout
      @messages = []
    end
  end
end
