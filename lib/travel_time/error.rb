# frozen_string_literal: true

module TravelTime
  # The Error class wraps exceptions and provide useful information.
  class Error < StandardError
    attr_reader :response

    def initialize(response: nil, message: nil)
      @response = response
      @message = message.nil? ? @response&.body&.[]('description') : message
      super(@message)
    end
  end
end
