module Hyperstack
  def self.deprecation_warning(name, message)
    return if env.production?
    @deprecation_messages ||= []
    message = "Warning: Deprecated feature used in #{name}. #{message}"
    return if @deprecation_messages.include? message
    @deprecation_messages << message
    `console.warn.apply(console, [message])`
  end
end
