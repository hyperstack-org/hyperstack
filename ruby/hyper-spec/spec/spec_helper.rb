require 'hyper-spec'
require 'pry'
require 'opal-browser'

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path('../test_app/config/environment', __FILE__)

require 'rspec/rails'
require 'rspec-steps'
require 'timecop'

module Helpers
  def computed_style(selector, prop)
    page.evaluate_script(
      "window.getComputedStyle(document.querySelector('#{selector}'))['#{prop}']"
    )
  end
  def calculate_window_restrictions
    return if @min_width
    size_window(100,100)
    @min_width = width
    size_window(500,500)
    @height_adjust = 500-height
    size_window(6000, 6000)
    @max_width = width
    @max_height = height
  end
  def height
    evaluate_script('window.innerHeight')
  end
  def width
    evaluate_script('window.innerWidth')
  end
  def dims
    [width, height]
  end
  def adjusted(width, height)
    [[@max_width, [width, @min_width].max].min, [@max_height, height-@height_adjust].min]
  end
end

RSpec.configure do |config|
  config.include Helpers
  # config.after :each do
  #   Rails.cache.clear
  # end

  config.before :suite do
    MiniRacer_Backup = MiniRacer
    Object.send(:remove_const, :MiniRacer)
  end

  config.around(:each, :prerendering_on) do |example|
    MiniRacer = MiniRacer_Backup
    example.run
    Object.send(:remove_const, :MiniRacer)
  end
end
