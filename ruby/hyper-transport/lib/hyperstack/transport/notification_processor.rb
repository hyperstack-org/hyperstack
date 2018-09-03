module Hyperstack
  module Transport
    class NotificationProcessor
      def self.process_notification(notification_hash)
        if notification_hash.has_key?(:notification)
          notification_hash[:notification].keys.each do |key|
            "::#{key.underscore.camelize}".constantize.process_notification(notification_hash[key])
          end
        else
          notification_hash.keys.each do |key|
            "::#{key.underscore.camelize}".constantize.process_response(notification_hash[key])
          end
        end
      end
    end
  end
end