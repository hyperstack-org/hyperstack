module HyperRecord
  class Collection < Array
    def initialize(array, record = nil, relation_name = nil)
      @record = record
      @relation_name = relation_name
      if array
        array.each do |record|
          record._register_collection(self)
        end
      end
      @record._notify_observers if @record
      array ? super(array) : super
    end

    def <<(other_record)
      if @record && @relation_name
        @record.link_record(other_record, @relation_name)
      end
      other_record._register_collection(self)
      @record._notify_observers if @record
      super(other_record)
    end

    def delete(other_record)
      if @record && @relation_name && !other_record.instance_variable_get(:@remotely_destroyed)
        @record.unlink_record(other_record, @relation_name)
      end
      other_record._unregister_collection(self)
      @record._notify_observers if @record
      super(other_record)
    end

    def push(other_record)
      other_record._register_collection(self)
      @record._notify_observers if @record
      super(other_record)
    end
  end
end
