# frozen_string_literal: true

require 'dry/configurable'
require 'travel_time/client'
require 'travel_time/version'

# Main TravelTime module
module TravelTime
  extend Dry::Configurable

  setting :http_adapter
  setting :application_id
  setting :api_key

  class Error < StandardError; end
end
