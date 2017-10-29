class Nav < Hyperloop::Component

  before_mount do
    mutate.user_name_input ''
  end

  render do
    div.navbar.navbar_inverse.navbar_fixed_top do
      div.container do
        div.collapse.navbar_collapse(id: 'navbar') do
          form.navbar_form.navbar_left(role: :search) do
            div.form_group do
              input.form_control(type: :text, value: state.user_name_input, placeholder: "Enter Your Handle"
              ).on(:change) do |e|
                mutate.user_name_input e.target.value
              end
              button.btn.btn_default(type: :button) { "login!" }.on(:click) do
                Operations::Join.run(user_name: state.user_name_input)
              end if valid_new_input?
            end
          end
        end
      end
    end
  end

  def valid_new_input?
    state.user_name_input.present? && state.user_name_input != MessageStore.user_name
  end
end
