class ActiveRecord::Base
  [:view, :create, :update, :destroy].each do |access|
    define_method("#{access}_permitted?".to_sym) { |attr = nil| true }
  end
end
