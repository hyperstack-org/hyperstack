module Hyperstack
  module Record
    class Collection < Array

      # initialize new Hyperstack::Record::Collection, used internally
      #
      # @param collection [Hyperstack::Record::Collection] or [Array] of records or empty [Array]
      # @param record [Hyperstack::Record] optional base record this collection belongs to
      # @param relation_name [String] optional base record relation name this collection represents
      def initialize(collection = [], record = nil, relation_name = nil)
        @record = record
        @relation_name = relation_name
        if collection
          collection.each do |record|
            record._register_collection(self)
          end
        end
        @record.notify_observers if @record
        collection ? super(collection) : super
      end

      # add record to collection, record is saved to db, success assumed
      #
      # @param other_record [Hyperstack::Record] record to add
      def <<(other_record)
        if @record && @relation_name
          @record.promise_link(other_record, @relation_name)
        end
        other_record._register_collection(self)
        @record.notify_observers if @record
        super(other_record)
      end

      # delete record from collection, saved to db, success assumed
      #
      # @param other_record [Hyperstack::Record] record to delete from collection
      def delete(other_record)
        if @record && @relation_name && !other_record.instance_variable_get(:@remotely_destroyed)
          @record.promise_unlink(other_record, @relation_name)
        end
        other_record._unregister_collection(self)
        @record.notify_observers if @record
        super(other_record)
      end

      # add record to collection, not saved to db
      #
      # @param other_record [Hyperstack::Record] record to add
      def push(other_record)
        other_record._register_collection(self)
        @record.notify_observers if @record
        super(other_record)
      end
    end
  end
end
