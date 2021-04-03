class Time
  def to_json
    strftime("%FT%T.%3N%z").to_json
  end
end
