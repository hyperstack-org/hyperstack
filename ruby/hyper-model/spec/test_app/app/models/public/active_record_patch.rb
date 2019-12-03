class ActiveRecord::Base
  def new?
    raise 'Hypermodel internally using the deprecated new? method'
  end
end
