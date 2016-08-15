module ActiveRecord
  module InstanceMethods
    def previous_changes
      @backing_record.previous_changes
    end
  end
end
