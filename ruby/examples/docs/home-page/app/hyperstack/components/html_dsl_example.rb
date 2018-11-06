class HtmlDslExample < HyperComponent
  # Notice that HTML elements are in CAPS
  # You can specify the CSS class on any HTML element

  render(DIV) do
    div(class: 'ui info message') do
      h3 { 'Blue Box' }
    end

    table(class: 'ui celled table') do
      thead do
        tr do
          th { 'One' }
          th { 'Two' }
          th { 'Three' }
        end
      end
      tbody do
        tr do
          td { 'A' }
          td(class: 'negative') { 'B' }
          td { 'C' }
        end
      end
    end

    ul do
      10.times { |n| li { "Number #{n}" }}
    end
  end
end
