# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  minimum_coverage 100
  minimum_coverage_by_file 100
end

require 'travel_time'
require 'dry/configurable/test_interface'
require 'webmock/rspec'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    TravelTime.reset_config
  end
end

# Enable the test interface for the TravelTime module to
# allow calling `reset_config` on it.
module TravelTime
  enable_test_interface
end
