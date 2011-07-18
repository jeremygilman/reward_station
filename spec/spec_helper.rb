require 'bundler'
Bundler.setup

require 'reward_station'

RSpec.configure do |config|
  config.mock_with :rspec
  config.include Savon::Macros
end


