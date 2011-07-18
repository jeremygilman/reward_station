# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "reward_station/version"

Gem::Specification.new do |s|
  s.name        = "reward_station"
  s.version     = RewardStation::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stepan Filatov", 'Cloud Castle Inc.']
  s.email       = ["filatov.st@gmail.com"]
  s.homepage    = "https://github.com/sfilatov/reward_station"
  s.summary     = %q{Reward Station is a client library for rewardstation.com}
  s.description = %q{}

  s.rubyforge_project = "reward_station"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'savon', ">= 0.9.6"
end
