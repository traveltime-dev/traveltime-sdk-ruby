# frozen_string_literal: true

require 'faraday'
require 'travel_time/middleware/authentication'

module TravelTime
  # The Client class provides the main interface to interact with the TravelTime API
  class Client
    API_BASE_URL = 'https://api.traveltimeapp.com/v4/'

    attr_reader :connection

    def initialize
      @connection = Faraday.new(API_BASE_URL) do |f|
        f.request :json
        f.response :raise_error if TravelTime.config.raise_on_failure
        f.response :logger if TravelTime.config.enable_logging
        f.response :json
        f.use TravelTime::Middleware::Authentication
        f.adapter TravelTime.config.http_adapter || Faraday.default_adapter
      end
    end

    def unwrap(response)
      Response.from_object(response)
    end

    def perform_request
      unwrap(yield)
    rescue Faraday::Error => e
      raise TravelTime::Error.new(response: Response.from_hash(e.response)) if e.response

      raise TravelTime::Error.new(message: e.message)
    rescue StandardError => e
      raise TravelTime::Error.new(message: e.message)
    end

    def map_info
      perform_request { connection.get('map-info') }
    end
  end
end
