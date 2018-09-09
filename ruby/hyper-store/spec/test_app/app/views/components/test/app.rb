module Test
  class App < Hyperloop::Component
    before_mount do
      @store = Store.new
    end

    render(DIV) do
      TABLE do
        THEAD do
          TR do
            TH { '' }
            TH { 'Class' }
            TH { 'Instance' }
            TH { 'Shared' }
          end
        end
        TBODY do
          TR do
            TH { 'Class' }
            TD(id: :scc) { Store.state.class_class }
            TD(id: :sci) { @store.state.class_instance }
            TD(id: :scs) { @store.state.class_shared }
            TD(id: :scsf) { @store.state.instance_foo }
          end
          TR do
            TH { 'Singleton' }
            TD(id: :ssc) { Store.state.singleton_klass }
            TD(id: :ssi) { @store.state.singleton_instance }
            TD(id: :sss) { Store.state.singleton_shared }
            TD(id: :sssf) { Store.state.class_foo }
          end
          TR do
            TH { 'Mutate Class' }
            TD do
              BUTTON(id: :mcc) { 'Mutate CC' }
                .on(:click) { Store.mutate.class_class("#{Store.state.class_class} x") }
            end
            TD do
              BUTTON(id: :mci) { 'Mutate CI' }
                .on(:click) { @store.mutate.class_instance("#{@store.state.class_instance} x") }
            end
            TD do
              BUTTON(id: :mcs) { 'Mutate CS' }
                .on(:click) { @store.mutate.class_shared("#{@store.state.class_shared} x") }
            end
          end
          TR do
            TH { 'Mutate Singleton' }
            TD do
              BUTTON(id: :msc) { 'Mutate SC' }
                .on(:click) { Store.mutate.singleton_klass("#{Store.state.singleton_klass} x") }
            end
            TD do
              BUTTON(id: :msi) { 'Mutate SI' }
                .on(:click) { @store.mutate.singleton_instance("#{@store.state.singleton_instance} x") }
            end
            TD do
              BUTTON(id: :mss) { 'Mutate SS' }
                .on(:click) { Store.mutate.singleton_shared("#{Store.state.singleton_shared} x") }
            end
          end
        end
      end
    end
  end
end
