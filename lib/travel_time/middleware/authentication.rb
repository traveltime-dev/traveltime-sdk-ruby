# frozen_string_literal: true

require 'faraday'

module TravelTime
  module Middleware
    # The Authentication middleware is responsible for setting the auth headers
    # on each request. These are automatically taken from the `TravelTime.config`.
    class Authentication < Faraday::Middleware
      APP_ID_HEADER = 'X-Application-Id'
      API_KEY_HEADER = 'X-Api-Key'
      USER_AGENT = 'User-Agent'

      def on_request(env)
        env.request_headers[APP_ID_HEADER] = TravelTime.config.application_id
        env.request_headers[API_KEY_HEADER] = TravelTime.config.api_key
        env.request_headers[USER_AGENT] = 'Travel Time Ruby SDK'
      end
    end
  end
end
