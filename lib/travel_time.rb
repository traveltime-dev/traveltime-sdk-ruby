# frozen_string_literal: true

require 'dry/configurable'
require 'travel_time/client'
require 'travel_time/error'
require 'travel_time/response'
require 'travel_time/version'

# Main TravelTime module
module TravelTime
  extend Dry::Configurable

  # Authentication
  setting :application_id
  setting :api_key

  # HTTP Client
  setting :http_adapter
  setting :enable_logging, default: false
  setting :raise_on_failure, default: false

  # Response preferences
  setting :parse_geo_json, default: true
end
