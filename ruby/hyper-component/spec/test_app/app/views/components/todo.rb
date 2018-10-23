module Components
  class Todo
    include Hyperstack::Component
    export_component

    params do
      requires :todo
    end

    def render
      LI { "#{params[:todo]}" }
    end
  end
end
