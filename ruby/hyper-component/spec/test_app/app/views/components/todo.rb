module Components
  class Todo
    include Hyperloop::Component::Mixin
    export_component

    params do
      requires :todo
    end

    def render
      li { "#{params[:todo]}" }
    end
  end
end
