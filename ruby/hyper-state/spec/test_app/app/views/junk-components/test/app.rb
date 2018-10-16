module Test
  class App
    include Hyperstack::Component::Mixin
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
            TD(id: :scc) { Store.class_class.state }
            TD(id: :sci) { @store.class_instance.state }
            TD(id: :scs) { @store.class_shared.state }
            TD(id: :scsf) { @store.instance_foo.state }
          end
          TR do
            TH { 'Singleton' }
            TD(id: :ssc) { Store.singleton_klass.state }
            TD(id: :ssi) { @store.singleton_instance.state }
            TD(id: :sss) { Store.singleton_shared.state }
            TD(id: :sssf) { Store.class_foo.state }
          end
          TR do
            TH { 'Mutate Class' }
            TD do
              BUTTON(id: :mcc) { 'Mutate CC' }
                .on(:click) { Store.class_class = "#{Store.state.class_class} x" }
            end
            TD do
              BUTTON(id: :mci) { 'Mutate CI' }
                .on(:click) { @store.class_instance = "#{@store.state.class_instance} x" }
            end
            TD do
              BUTTON(id: :mcs) { 'Mutate CS' }
                .on(:click) { @store.class_shared = "#{@store.state.class_shared} x" }
            end
          end
          TR do
            TH { 'Mutate Singleton' }
            TD do
              BUTTON(id: :msc) { 'Mutate SC' }
                .on(:click) { Store.singleton_klass = "#{Store.state.singleton_klass} x" }
            end
            TD do
              BUTTON(id: :msi) { 'Mutate SI' }
                .on(:click) { @store.singleton_instance = "#{@store.state.singleton_instance} x" }
            end
            TD do
              BUTTON(id: :mss) { 'Mutate SS' }
                .on(:click) { Store.singleton_shared = "#{Store.state.singleton_shared} x" }
            end
          end
        end
      end
    end
  end
end
