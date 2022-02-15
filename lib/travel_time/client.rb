# frozen_string_literal: true

require 'faraday'
require 'travel_time/middleware/authentication'

module TravelTime
  # The Client class provides the main interface to interact with the TravelTime API
  #
  # @usage
  #   credentials = {}
  #   client = TravelTime::Client.new(credentials)
  #   client.map_info
  class Client
    API_BASE_URL = 'https://api.traveltimeapp.com/v4/'

    def initialize
      @conn = Faraday.new(API_BASE_URL) do |f|
        f.request :json
        f.response :logger
        f.response :json
        f.use TravelTime::Middleware::Authentication
        f.adapter TravelTime.config.http_adapter || Faraday.default_adapter
      end
    end

    def map_info
      unwrap(@conn.get('map-info'))
    end

    def unwrap(response)
      response.body
    end
  end
end
