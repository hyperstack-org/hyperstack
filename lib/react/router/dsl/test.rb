# class Foo < React::Component::Base
#   def render
#     puts "count: #{children.count}"
#     div do
#       children.each { |child| div {child.render} }
#     end
#   end
# end
#
# class Baz < React::Component::Base
#   def render
#     puts "rendering baz now"
#     "Bazzy".span
#   end
# end

# class Bar < React::Component::Base
#   def render
#     Foo() {  "foo".span; Baz(); "bar".span }
#   end
# end
