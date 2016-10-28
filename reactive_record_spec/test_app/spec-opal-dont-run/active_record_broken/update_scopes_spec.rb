require 'spec_helper'

describe "updating scopes" do

  # this spec needs some massive cleanup... the rendering tests continue to run... that needs to be fixed

  # the tests depend on each other.

  # there are no test for nested scopes like User.todos.active for example which will certainly fail

  rendering("saving a new record will update .all and cause a rerender") do
    unless @starting_count
      TodoItem.all.last.title
      unless TodoItem.all.count == 1
        @starting_count = TodoItem.all.count

        after(0.1) do
          TodoItem.new(title: "play it again sam").save
        end
      end
    end
    (TodoItem.all.count - (@starting_count || 100)).to_s
  end.should_generate do
    html == "1"
  end

  rendering("adding a new matching record will add the record to a scope using abbreviated to_sync macro") do
    unless @starting_count
      unless TodoItem.important.first.description.loading?
        @starting_count = TodoItem.important.count
        after(0.1) do
          td = TodoItem.new(description: "another big mitch todo XXX")
          td.save do
            puts "after save, pushing #{TodoItem.important} << #{td}"
            #TodoItem.important << td
          end
        end
      end
    end
    (TodoItem.important.count - (@starting_count || 100)).to_s
  end.should_generate do
    html == "1"
  end  # BROKEN FROM HERE

  rendering("adding a new matching record will add the record to a scope using abbreviated to_sync macro") do
    unless @starting_count
      unless TodoItem.important.first.description.loading?
        @starting_count = TodoItem.important.count
        after(0.1) do
          TodoItem.new(description: "another big mitch todo XXX").save
        end
      end
    end
    (TodoItem.important.count - (@starting_count || 100)).to_s
  end.should_generate do
    html == "1"
  end

  rendering("adding a new matching record will add the record to a scope using full to_sync macro") do
    unless @starting_count
      unless TodoItem.active.first.title.loading?
        @starting_count = TodoItem.active.count
        after(0.1) do
          TodoItem.new(title: "another big mitch todo XXX").save
        end
      end
    end
    (TodoItem.active.count - (@starting_count || 100)).to_s
  end.should_generate do
    html == "1"
  end

  rendering("destroying records will cause a re-render") do
    unless @starting_count
      TodoItem.all.last.title
      unless TodoItem.all.count == 1
        @starting_count = TodoItem.all.count
        after(0.1) do
          TodoItem.all.last.destroy do
            TodoItem.all.last.destroy do
              TodoItem.all.last.destroy do
                TodoItem.all.last.destroy
              end
            end
          end
        end
      end
    end
    (TodoItem.all.count - (@starting_count || 100)).to_s
  end.should_generate do
    html == "-3"
  end

end
