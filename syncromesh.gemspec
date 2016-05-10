# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib/', __FILE__)

require 'syncromesh/version'

Gem::Specification.new do |s|

    s.name          = "syncromesh"
    s.version       = Syncromesh::VERSION
    s.authors       = ["Mitch VanDuyn"]
    s.email         = ["mitch@catprint.com"]

    s.summary       = "Synchronization of active record models across multiple clients using Pusher, ActionCable, or Polling"
    s.description   = "Work in progress"
    s.homepage      = "https://github.com/reactive-ruby/syncromesh"
    s.license       = "MIT"

    s.files          = `git ls-files`.split("\n")
    s.executables    = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
    s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
    s.require_paths  = ['lib']
end
