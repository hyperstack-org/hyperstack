module ActiveModel
  class Error

    attr_reader :messages

    def initialize(initial_msgs = {})
      @messages = Hash.new { |h, k| h[k] = [] }
      initial_msgs.each { |attr, msgs| @messages[attr] = msgs.uniq }
    end

    def [](attribute)
      messages[attribute]
    end

    def delete(attribute)
      messages.delete(attribute)
    end

    def empty?
      messages.empty?
    end

    def clear
      @messages.clear
    end

    def add(attribute, message:)
      @messages[attribute] << message unless @messages[attribute].include? message
    end
  end
end
