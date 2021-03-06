# frozen_string_literal: true

module TravelTime
  # The Error class wraps exceptions and provide useful information.
  class Error < StandardError
    DEFAULT_MESSAGE = 'Error while processing the request'

    attr_reader :response, :wrapped_exception

    def initialize(message = nil, response: nil, exception: nil)
      @response = response
      @wrapped_exception = exception
      exc = super(parse_message(message))
      exc.set_backtrace(exception.backtrace) unless exception.nil?
    end

    def parse_message(message)
      message || wrapped_exception&.message || description || DEFAULT_MESSAGE
    end

    def description
      extract_from_body('description')
    end

    def error_code
      extract_from_body('error_code')
    end

    def additional_info
      extract_from_body('additional_info')
    end

    def documentation_link
      extract_from_body('documentation_link')
    end

    private

    def extract_from_body(field)
      response&.body&.[](field)
    end
  end
end
