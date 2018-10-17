module Hyperstack
  module Internal
    module State
      # State::Mapper bidirectionally maps observers to objects during a rendering cycle.

      # Observers:  Any object that responds to the `mutations` method can become
      # an observer by calling Mapper.observing.

      # State Objects: any object can be observed by calling the observed! method, and
      # an object indicates that it has changed state by calling the mutated! method,
      # which will notify all observers via their mutations methods.

      # During each rendering cycle a list of objects observed during rendering
      # is built called new_objects.

      # At the end of the rendering cycle new_objects becomes current_objects, and
      # its inverse called current_observers.

      # When mutated! is called, the current_observers list is used to find the list of
      # observers.

      # Typically mutated! is called during some javascript event, and we will want to
      # delay notification until the event handler has completed execution.
      module Mapper
        @rendering_level = 0

        class << self
          # Entry Points:
          #   observing                 setup an observer
          #   observed!                 indicate an object has been observed
          #   mutated!                  indicate an object has been mutated
          #   observed?                 has this object been observed?
          #   bulk_update               prevent notifications until the event completes
          #   update_objects_to_observe called at end of each rendering cycle
          #   remove                    called when a component unmounts

          # Observers wrap code in observe.  Any calls
          # made to the public entry points will then know which
          # observer is executing, along with whether this is the
          # outer most component, and whether to delay or handle state
          # changes immediately.

          # Once the observer's block completes execution, the
          # context instance variables are restored.
          def observing(observer, immediate_update, rendering, update_objects)
            saved_context = [@current_observer, @immediate_update]
            @current_observer = observer
            @immediate_update = immediate_update && observer
            @rendering_level += 1 if rendering
            observed!(observer)
            observed!(observer.class)
            return_value = yield
            update_objects_to_observe(observer) if update_objects
            return_value
          ensure
            @current_observer, @immediate_update = saved_context
            @rendering_level -= 1 if rendering
            return_value
          end

          # called when an object has been observed (i.e. read) by somebody
          def observed!(object)
            return unless @current_observer
            new_objects[@current_observer] << object
            return unless update_exclusions[object]
            update_exclusions[object] << @current_observer
          end

          # Called when an object has been mutated.
          # Depending on the state of StateContext we will either
          # schedule the update notification for later, immediately
          # notify any observers, or do nothing.
          def mutated!(object)
            if delay_updates?(object)
              schedule_delayed_updater(object)
            elsif @rendering_level.zero?
              current_observers[object].each do |observer|
                observer.mutations([object])
              end
            end
          end

          # Check to see if an object has been observed.
          def observed?(object)
            # we don't want to unnecessarily create a reference to ourselves
            # in the current_observers hash so we just look for the key.
            current_observers.key? object
          end

          # Code can be wrapped in the bulk_update method, and
          # notifications of any mutations that occur during
          # the yield will be scheduled for after the current
          # event finishes.
          def bulk_update
            saved_bulk_update_flag = @bulk_update_flag
            @bulk_update_flag = true
            yield
          ensure
            @bulk_update_flag = saved_bulk_update_flag
          end

          # Call after each component updates. (in the after_update/after_mount callbacks)
          # During the rendering cycle the observers and objects are held in the
          # current_observers and current_objects hashes, which are just inverses of each
          # so that current_observers can be accessed via objects, and current_objects can be
          # accessed by observers.

          # While rendering is going on, observers may add new objects to the new_objects list

          # When rendering completes we clear the current observers and objects lists, and
          # the new_objects list gets transferred in to current_objects and current_observers
          # and the process repeats.

          # When an event triggers a state change the current_objects list is used to determine
          # what observers (components) need to be updated.  Note that the new_objects during this
          # phase is still empty, and that is why we need two lists.

          # TODO: see if we can get rid of all this and simply calling
          # remove_current_observers_and_objects at the START of each components rendering
          # cycle (i.e. before_mount and before_update)
          def update_objects_to_observe(observer = @current_observer)
            remove_current_observers_and_objects(observer)
            objects = new_objects.delete(observer)
            objects.each { |object| current_observers[object] << observer } if objects
            current_objects[observer] = objects
          end

          # call remove before unmounting components to prevent stray events
          # from being sent to unmounted components.
          def remove(observer = @current_observer)
            remove_current_observers_and_objects(observer)
            new_objects.delete observer
          end

          # Internal (Private) Methods

          # These four hashes track the current relationship between
          # observers and observable objects

          # new_objects are added as the @current_observer reads
          # an objects state
          def new_objects
            @new_objects ||= Hash.new { |h, k| h[k] = Set.new }
          end

          # at the end of the rendering cycle the new_objects are
          # processed into a list of observers indexed by objects...
          def current_observers
            @current_observers ||= Hash.new { |h, k| h[k] = [] }
          end

          # and a list of objects indexed by observers
          def current_objects
            @current_objects ||= Hash.new { |h, k| h[k] = [] }
          end

          # Normally notification of changes to state are queued up
          # and will be run after the event has completed processing.
          # Then each observer is notified of the states that changed
          # during the event.  The observers may then begin reading
          # state before the notification has completed.  To prevent
          # redundant notifications in this case, a list of observers
          # indexed by objects is kept in the update_exclusions hash.

          # We avoid keeping empty lists of observers on the exclusion
          # lists by not adding an object hash key unless the object
          # already has pending state changes. (See the
          # schedule_delayed_updater method below)
          def update_exclusions
            @update_exclusions ||= Hash.new
          end

          # remove_current_observers_and_objects clears the hashes between renders
          def remove_current_observers_and_objects(observer)
            raise 'state management called outside of watch block' unless observer
            deleted_objects = current_objects.delete(observer)
            return unless deleted_objects
            deleted_objects.each do |object|
              # to allow for GC we never want objects hanging around as keys in
              # the current_observers hash, so we tread carefully here.
              next unless current_observers.key? object
              current_observers[object].delete(observer)
              current_observers.delete object if current_observers[object].empty?
            end
          end

          # determine if updates should be delayed.
          # always delay updates if the bulk_update_flag is set
          # otherwise delayed updates only occurs if
          # Hyperstack.on_client? is true WITH ONE EXCEPTION:
          # observers can indicate that they need immediate updates in
          # case that the object being updated is themselves.
          def delay_updates?(object)
            @bulk_update_flag ||
              (Hyperstack.on_client? &&
                (@immediate_update != @current_observer || @current_observer != object))
          end

          # schedule_delayed_updater adds a new set to the
          # update_exclusions hash (indexed by object) then makes
          # sure that the updater is scheduled to run as soon as the current
          # event completes.

          # the update_exclusions hash tells us two things.  First any object that
          # is a key in the hash has been changed, but the notification of the change
          # has been delayed.  Secondly the associated Set will contain a list of observers
          # that have already read the current state, between the time
          # schedule_delayed_updater has been called, and the updater runs.  These
          # observers don't need notification since they already know the current state.

          # If an object changes state again then the Set will be reinitialized, and all
          # the observers that might have been on a previous exclusion list, will now be
          # notified.
          def schedule_delayed_updater(object)
            update_exclusions[object] = Set.new
            @delayed_updater ||= after(0) do
              current_update_exclusions = @update_exclusions
              @update_exclusions = @delayed_updater = nil
              observers_to_update(current_update_exclusions).each do |observer, objects|
                observer.mutations objects
              end
            end
          end

          # observers_to_update returns a hash with observers as keys, and lists of objects
          # as values. The hash is built by filtering the current_observers list
          # including only observers that have mutated objects, that are not on the exclusion
          # list.
          def observers_to_update(exclusions)
            Hash.new { |hash, key| hash[key] = Array.new }.tap do |updates|
              exclusions.each do |object, excluded_observers|
                current_observers[object].each do |observer|
                  next if excluded_observers.include?(observer)
                  updates[observer] << object
                end
              end
            end
          end
        end
      end
    end
  end
end
