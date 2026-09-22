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

    def self.from_object_proto(response, decoder: nil)
      body = if response.success?
               decoder ? decoder.call(response.body) : ProtoUtils.decode_proto_response(response.body)
             else
               proto_error(response.headers)
             end
      new(status: response.status, headers: response.headers, body: body)
    end

    def self.from_hash(response)
      new(
        status: response[:status],
        headers: response[:headers],
        body: response[:body]
      )
    end

    def self.from_proto_error(response)
      new(
        status: response[:status],
        headers: response[:headers],
        body: proto_error(response[:headers])
      )
    end

    # Keyed by the fields TravelTime::Error reads from a JSON error body. Header values are always
    # strings, where the JSON API gives an integer error_code and a hash additional_info.
    def self.proto_error(headers)
      {
        'error_code' => headers['X-ERROR-CODE'],
        'description' => headers['X-ERROR-MESSAGE'],
        'additional_info' => headers['X-ERROR-DETAILS']
      }
    end
    private_class_method :proto_error

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
