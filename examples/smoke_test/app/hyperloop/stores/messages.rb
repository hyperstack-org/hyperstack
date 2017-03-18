class Messages < Hyperloop::Store
  state messages: [], scope: :class, reader: :all 
  receives(SendToAll) { |params| mutate.messages << params.message }
end
