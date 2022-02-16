# frozen_string_literal: true

require 'travel_time'
require 'dry/configurable/test_interface'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:all) do
    TravelTime.reset_config
  end
end

# Enable the test interface for the TravelTime module to
# allow calling `reset_config` on it.
module TravelTime
  enable_test_interface
end
