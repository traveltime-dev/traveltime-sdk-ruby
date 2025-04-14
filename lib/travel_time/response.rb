# frozen_string_literal: true

require 'faraday'

module TravelTime
  # The Response class represent an API response.
  class Response
    attr_reader :status, :body, :headers

    def self.from_object(response)
      new(
        status: response.status,
        headers: response.headers,
        body: response.body
      )
    end

    def self.from_object_proto(response)
      resp = new(
        status: response.status,
        headers: response.headers,
        body: nil
      )

      # Only try to decode if it's a successful response
      resp.instance_variable_set(:@body, ProtoUtils.decode_proto_response(response.body)) if resp.success?

      resp
    end

    def self.from_hash(response)
      new(
        status: response[:status],
        headers: response[:headers],
        body: response[:body]
      )
    end

    def initialize(status: nil, headers: nil, body: nil)
      @status = status
      @headers = headers
      @body = body
    end

    def success?
      (200..299).cover?(status)
    end
  end
end
