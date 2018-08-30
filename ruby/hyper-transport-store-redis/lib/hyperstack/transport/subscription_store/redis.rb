require 'redis'

module Hyperstack
  module Transport
    module SubscriptionStore
      class Redis
        def self.scrub_time
          @scrub_time ||= if Hyperstack.redis_options.has_key?(:scrub_time)
                            Hyperstack.redis_options[:scrub_time].to_f
                          else
                            8.hours.to_f
                          end
        end

        def self.redis_instance
          @redis_instance ||= if Hyperstack.redis_options && Hyperstack.redis_options != {}
                                ::Redis.new(Hyperstack.redis_options)
                              else
                                ::Redis.new
                              end
        end

        def self.has_multi_del
          @has_multi_del ||= Gem::Version.new(::Redis::VERSION) >= Gem::Version.new('4.0.2')
        end

        def self.delete_all_subscriptions(object_string)
          redis_instance.del(object_string)
        end

        def self.delete_subscription(object_string, subscriber)
          redis_instance.hdel(object_string, subscriber)
        end

        def self.get_subscribers(object_string)
          all_subscribers = redis_instance.hgetall(object_string)
          valid_subscribers = []
          obsolete_subscribers = []

          final_scrub_time = Time.now.to_f - scrub_time

          all_subscribers.each do |subscriber, last_requested|
            if last_requested.to_time.to_f < final_scrub_time
              obsolete_subscribers << subscriber
              next
            end

            valid_subscribers << subscriber
          end

          if obsolete_subscribers.any?
            if has_multi_del
              redis_instance.hdel(object_string, *obsolete_subscribers)
            else
              obsolete_subscribers.each do |obsolete_subscriber|
                redis_instance.hdel(object_string, obsolete_subscriber)
              end
            end
          end

          valid_subscribers
        end

        def self.get_and_touch_subscribers(object_string)
          valid_subscribers = get_subscribers(object_string)
          if valid_subscribers.any?
            time_now = Time.now
            args = valid_subscribers.map { |subscriber| [subscriber, time_now] }
            args.flatten!
            redis_instance.hmset(object_string, *args)
          end
          valid_subscribers
        end

        def self.save_subscription(object_string, subscriber)
          redis_instance.hset(object_string, subscriber, Time.now)
        end

        def self.save_subscriptions(object_strings, subscriber)
          time_now = Time.now
          redis_instance.pipelined do
            object_strings.each do |object_string|
              redis_instance.hset(object_string, subscriber, time_now)
            end
          end
        end
      end
    end
  end
end