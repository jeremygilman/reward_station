# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "reward_station/version"

Gem::Specification.new do |s|
  s.name        = "reward_station"
  s.version     = RewardStation::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stepan Filatov"]
  s.email       = ["filatov.st@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Reward Station is a client implementation of the Xceleration Reward Station service API}
  s.description = %q{Reward Station is a client implementation of the Xceleration Reward Station service API}

  s.rubyforge_project = "reward_station"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
