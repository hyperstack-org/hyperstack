module ReactiveRecord
  class WhileLoading
    def self.has_observers?
      React::State.has_observers?(self, :loaded_at)
    end
  end
end
