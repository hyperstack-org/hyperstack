class Message < Hyperloop::Component
  param :message, type: Hash

  after_mount :scroll_to_bottom
  after_update :scroll_to_bottom

  def render
   div.row.alternating.message do
     div.col_sm_2 { params.message[:from] }
     FormattedDiv class: 'col-sm-8', markdown: params.message[:message]
     div.col_sm_2 { formatted_time }
   end
  end

  def scroll_to_bottom
    Element['html, body'].animate({ scrollTop: Element[Document].height }, :slow)
  end

  def formatted_time
    time = params.message[:time]
    if Time.now < time + 1.day
      time.strftime '%I:%M %p'
    elsif Time.now < time + 7.days
      time.strftime '%A'
    else
      time.strftime '%D %I:%M %p'
    end
  end
end
