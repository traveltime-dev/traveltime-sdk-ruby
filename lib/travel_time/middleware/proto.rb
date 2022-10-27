# frozen_string_literal: true

require 'faraday'
require 'base64'

module TravelTime
  module Middleware
    # The Proto middleware is responsible for setting the basic auth headers for proto requests
    # on each request. These are automatically taken from the `TravelTime.config`.
    class ProtoMiddleware < Faraday::Middleware
      def on_request(env)
        env.request_headers['Authorization'] =
          "Basic #{Base64.encode64("#{TravelTime.config.application_id}:#{TravelTime.config.api_key}")}"
        env.request_headers['Content-Type'] = 'application/octet-stream'
        env.request_headers['Accept'] = 'application/octet-stream'
      end
    end
  end
end
