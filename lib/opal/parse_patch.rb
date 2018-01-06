begin
  JSON.parse("test")
rescue Exception => e
  JSON.class_eval do
    class << self
      alias old_parse parse
    end
    def self.parse(*args, &block)
      old_parse(*args, &block)
    rescue Exception => e
      raise StandardError.new e.message
    end
  end unless e.is_a? StandardError
end
