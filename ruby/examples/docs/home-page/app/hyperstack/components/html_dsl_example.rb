class HtmlDslExample < HyperComponent
  # Notice that HTML elements are in CAPS
  # You can specify the CSS class on any HTML element

  render(DIV) do
    DIV(class: 'ui info message') do
      H3 { 'Blue Box' }
    end

    TABLE(class: 'ui celled table') do
      THEAD do
        TR do
          TH { 'One' }
          TH { 'Two' }
          TH { 'Three' }
        end
      end
      TBODY do
        TR do
          TD { 'A' }
          TD(class: 'negative') { 'B' }
          TD { 'C' }
        end
      end
    end

    UL do
      10.times { |n| LI { "Number #{n}" }}
    end
  end
end
