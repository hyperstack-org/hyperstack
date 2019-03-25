require 'hyperloop-config'
require 'rubygems'
require 'opal-rails'
require 'hyper-operation'
require 'hyper-store'
require 'opal-browser'
require 'opal-jquery'
require 'uglifier'
require 'react-rails'

desc 'Build Hyperloop and Opal Compiler'
task :build do
  Opal.append_path 'lib'
  puts "About to build hyper-console-client.js"
  File.binwrite 'lib/hyper-console-client.js', Opal::Builder.build('hyperloop/console/hyper-console-client-manifest').to_s
  puts "done"
end

desc 'Minify using uglifier gem'
task :minify do
  puts "About to build hyper-console-client.min.js"
  js_file = "lib/hyper-console-client.js"
  js_min_file = "lib/hyper-console-client.min.js"
  File.open(js_min_file, "w").write(Uglifier.new(:harmony => true).compile(File.read(js_file)))
  puts "done"
end
task default: [:build, :minify]
