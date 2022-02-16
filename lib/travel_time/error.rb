# frozen_string_literal: true

module TravelTime
  # The Error class wraps exceptions and provide useful information.
  class Error < StandardError
    DEFAULT_MESSAGE = 'Error while processing the request'

    attr_reader :response

    def initialize(response: nil, message: nil)
      @response = response
      super(message || @response&.body&.[]('description') || DEFAULT_MESSAGE)
    end
  end
end
