require 'bundler'
Bundler.setup

require 'reward_station'

require "savon_helper"
RSpec.configure do |config|
  config.mock_with :rspec
  config.include Savon::Spec::Macros
end


