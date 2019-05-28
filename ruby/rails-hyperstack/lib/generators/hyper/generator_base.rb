require 'rails/generators'
module Hyper
  class GeneratorBase < Rails::Generators::Base
    class << self
      alias rails_inherited inherited
      def inherited(child)
        rails_inherited(child)
        child.class_eval do
          source_root File.expand_path('../templates', __FILE__)
          argument :components, type: :array
          class_option 'base-class', :default => nil # will pull in value from config setting
          class_option 'add-route', :default => nil
          class_option 'no-help', :default => nil
        end
      end
    end
  end
end
