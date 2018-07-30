module Hyperloop
  module TRansport
    class NotificationProcessor
      def self.process_notification(notification_hash)
        notification_hash.keys.each do |key|
          key.underscore.camelize.constantize.process_notification(notification_hash[key])
        end
      end
    end
  end
end