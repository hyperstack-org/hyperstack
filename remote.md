```ruby
class Model < ActiveRecord::Base

  def <=>(other)
    self.text.downcase <=> other.text.downcase
  end

  scope :sorted, -> { order('lower(text) ASC')}, client: -> { sort }

  scope :proper_nouns, -> { where('lower(text) <> text ')}, client: -> (r) { r.text.downcase != r.text }
end
```

if the remote proc takes a param it is given each record to check  (i.e. its wrapped in a select)

if there is no param the proc is executed in context of a collection which it can return a modified version of.

How:

three kinds of scopes:

Base collections (i.e. has_many, all, and unscoped)

outer scopes (i.e. directly following a base collection  Model.sorted === Model.all.sorted parent.children.proper_nouns )

inner scopes (i.e. other scopes that follow outer scopes)


First we need to update the base collections based on the changed models.  By definition everything we need to know to update the base scopes is available in the changed record.

+ has_many collections get updated by the load_from_json method
+ all, and unscoped get updated by a new method on the class:  update_base_scopes (maybe not needed?  )

Then we need to find all the outer scopes in the world.

To do this whenever an scope is applied, if it is being applied to a base collection (or to a Model itself which is equivilent to applying it Model.all) then it is added to a list, along with its parent base scope.

We can then iterate through this list.

During the iteration we do this:

```ruby
def update_collections(updated_record, base_collection, local_updates)
  if this scope is joined with the updated_record
    if local_updates && updated_record.class = self.class && my_client_proc
      local_updates << self
    else
      update_from_server
      client_procs = nil
    end
  end
  if children_collections
    children_collections.each { |child| child.update_collections(udpated_record, base_collection, client_procs)}
  elsif client_procs
    client_procs.inject(base_collection) do |collection, scope|
      dup collection into scope.all
      either call scope.proc with each record in a select
      or just call the proc in the context of scope
    end
  end
end
```

how about initial load?


1) if there is client_proc then run it on first load...

filter_most_out_on_server.filter_a_few_out_on_client  <- good
filter_a_few_out_on_client.filter_most_out_on_server <- blah

fix later...
or
as each scope is applied... of course we go back through all parent scopes and clear a filter flag (proc?)


then on a load as we add each scope in, we can do the initial filter right then... which is okay because
we don't have that data yet!!!

or don't even bother, just run the filter as things are replaced from the server...

its static... can always know if something should be filtered


arghhh...

Model.filter1.filter2...

its still true that to filter, all scopes in chain must be client filters.

but what is the diff between

Model.inc_filter1.coll_filter1.inc_filter2.coll_filter2

vs.

Model.coll_filter

right because this implies:

Model.all.coll_filter, which means we have to do Model.all.each  

but Model.all.inc_filter should just pass any new/changed entries to inc_filter, and then update the collection

Model.inc_filter1.inc_filter2

is okay because we should not have inc_filter1's collection all updated.

but really?  what if we are doing this:

Model.inc_minor_filter.inc_major_filter.count

We do not have to fetch all inc_minor_filter's collection ever.

We do not have to 
