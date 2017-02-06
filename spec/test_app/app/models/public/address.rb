class Address < ActiveRecord::Base
  
  MAPPED_FIELDS = %w(id street city state zip)
  
  def self.compose(*args)
    new.tap do |address|
      MAPPED_FIELDS.each_with_index do |field_name, i|
        address.send("#{field_name}=", args[i])
      end
    end
  end
  
end