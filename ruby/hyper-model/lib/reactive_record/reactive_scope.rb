# class ActiveRecord::Base
#
#   def self.to_sync(scope_name, opts={}, &block)
#     watch_list = if opts[:watch]
#       [*opts.delete[:watch]]
#     else
#       [self]
#     end
#     if RUBY_ENGINE=='opal'
#       watch_list.each do |klass_to_watch|
#         ReactiveRecord::Base.sync_blocks[klass_to_watch][self][scope_name] << block
#       end
#     else
#       # this is where we put server side watchers in place to sync all clients!
#     end
#   end
#
# end
