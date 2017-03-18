class FormattedDiv < Hyperloop::Component
  param :markdown, type: String
  collect_other_params_as :attributes

  def render
    div(params.attributes) do # send other attributes on to the outer div
      div(
        dangerously_set_inner_HTML:
          { __html: `marked(#{params.markdown}, {sanitize: true })` }
      )
    end
  end
end
