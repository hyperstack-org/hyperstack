class InputBox < Hyperloop::Component
  before_mount { mutate.composition '' }

  def render
    div.row.form_group.input_box.navbar.navbar_inverse.navbar_fixed_bottom do
      div.col_sm_1.white { 'Say: ' }
      textarea.col_sm_5(rows: rows, value: state.composition)
      .on(:change) do |e|
        mutate.composition e.target.value
      end
      .on(:key_down) do |e|
        send! if send_key?(e)
      end
      FormattedDiv class: 'col-sm-5 white', markdown: state.composition
    end
  end

  def rows
    [state.composition.count("\n") + 1, 20].min
  end

  def send_key?(e)
    (e.char_code == 13 || e.key_code == 13) && (e.meta_key || e.ctrl_key)
  end

  def send!
    Operations::Send message: mutate.composition(''), user_name: MessageStore.user_name
  end
end
