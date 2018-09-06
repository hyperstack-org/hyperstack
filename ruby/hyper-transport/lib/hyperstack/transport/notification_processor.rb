module Hyperstack
  module Transport
    class NotificationProcessor
      def self.process_notification(notification_hash)
        if notification_hash.has_key?(:notification)
          notification_hash[:notification].keys.each do |class_name|
            "::#{class_name.underscore.camelize}".constantize.process_notification(notification_hash[class_name])
          end
        else
          Hyperstack::Transport::ResponseProcessor.process_response(notification_hash)
        end
      end
    end
  end
end