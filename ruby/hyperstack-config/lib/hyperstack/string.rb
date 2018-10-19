# This will eventually be moved into Opal
class String
  def to_json
    `JSON.stringify(#{self})`
  end
end
