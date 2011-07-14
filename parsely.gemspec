# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "parsely"

Gem::Specification.new do |s|
  s.name        = "parsely"
  s.version     = Parsely::VERSION
  s.authors     = ["Gabriele Renzi"]
  s.email       = ["rff.rff+parsely@gmail.com"]
  s.homepage    = "http://github.com/riffraff/parsely"
  s.summary     = %q{a simple tool for text file wrangling}
  s.description = %q{parsely is a simple tool for managing text files.
                     Mostly to replace a lot of awk/sed/ruby/perl one-off scripts.
                     This is an internal release, guaranteed to break and ruin your life.}

  #s.rubyforge_project = "parsely"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_development_dependency "rake"
  
end
