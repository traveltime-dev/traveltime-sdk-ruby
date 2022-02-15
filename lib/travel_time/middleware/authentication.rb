# frozen_string_literal: true

require 'faraday'

module TravelTime
  module Middleware
    # The Authentication middleware is responsible for setting the auth headers
    # on each request. These are automatically taken from the `TravelTime.config`.
    class Authentication < Faraday::Middleware
      def on_request(env)
        env.request_headers['X-Application-Id'] = TravelTime.config.application_id
        env.request_headers['X-Api-Key'] = TravelTime.config.api_key
      end

      def map_info
        @conn.get('map-info')
      end
    end
  end
end
