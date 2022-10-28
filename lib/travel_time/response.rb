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
      new(
        status: response.status,
        headers: response.headers,
        body: ProtoUtils.decode_proto_response(response.body)
      )
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
