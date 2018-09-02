ActiveRecord::Base.send(:define_method, :react_serializer) do
  serializable_hash.merge(ReactiveRecord::Base.get_type_hash(self))
end

ActiveRecord::Relation.send(:define_method, :react_serializer) do
  all.to_a.react_serializer
end
