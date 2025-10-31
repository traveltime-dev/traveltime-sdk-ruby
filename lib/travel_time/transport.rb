# frozen_string_literal: true

module TravelTime
  # The Transport class provides a way to set transportation details
  class Transport
    attr_reader :type, :code, :url_name, :details

    # Define allowed details for each transport type
    ALLOWED_DETAILS = {
      'pt' => %i[walking_time_to_station],
      'driving+pt' => %i[walking_time_to_station driving_time_to_station parking_time]
    }.freeze

    PROTO_TRANSPORT_MAP = {
      pt: { code: 0, url_name: 'pt' },
      'driving+pt': { code: 2, url_name: 'pt' },
      driving: { code: 1, url_name: 'driving' },
      walking: { code: 4, url_name: 'walking' },
      cycling: { code: 5, url_name: 'driving' },
      'driving+ferry': { code: 3, url_name: 'driving+ferry' },
      'cycling+ferry': { code: 6, url_name: 'cycling+ferry' },
      'walking+ferry': { code: 7, url_name: 'walking+ferry' }
    }.freeze

    def initialize(transport_input)
      setup_type_and_details(transport_input)
      set_transport_info
    end

    # Validate that the provided details are allowed for this transport type
    def validate_details!
      return if @details.empty?

      validate_transport_type_supports_details
      validate_unexpected_details
    end

    def apply_to_proto(transportation)
      # Set the base type
      transportation.type = @code

      # Apply PublicTransport details - Only for type "pt" (code 0)
      apply_public_transport_details(transportation) if @code.zero? && @details[:walking_time_to_station]

      # Apply DrivingAndPublicTransport details - Only for type "driving+pt" (code 2)
      apply_driving_pt_details(transportation) if @code == 2

      transportation
    end

    private

    def setup_type_and_details(transport_input)
      if transport_input.is_a?(String)
        @type = transport_input
        @details = {}
      else
        @type = transport_input[:type]
        @details = transport_input.except(:type)
        validate_details!
      end
    end

    def set_transport_info
      info = PROTO_TRANSPORT_MAP[@type.to_sym]
      @code = info[:code]
      @url_name = info[:url_name]
    end

    def validate_transport_type_supports_details
      return if ALLOWED_DETAILS.key?(@type)

      detail_keys = @details.keys
      error_msg = "Transport type '#{@type}' doesn't support additional details, but #{detail_keys.join(', ')} provided"
      raise ArgumentError, error_msg
    end

    def validate_unexpected_details
      allowed = ALLOWED_DETAILS[@type]
      unexpected = @details.keys - allowed

      return if unexpected.empty?

      allowed_msg = allowed.empty? ? 'no details' : allowed.join(', ')
      error_msg = "Unexpected details for transport type '#{@type}': #{unexpected.join(', ')}. Allowed: #{allowed_msg}"
      raise ArgumentError, error_msg
    end

    def create_positive_uint32(value)
      Com::Igeolise::Traveltime::Rabbitmq::Requests::OptionalPositiveUInt32.new(value: value)
    end

    def create_non_negative_uint32(value)
      Com::Igeolise::Traveltime::Rabbitmq::Requests::OptionalNonNegativeUInt32.new(value: value)
    end

    def set_optional_fields(details_obj, field_mappings)
      field_mappings.each do |detail_key, field_info|
        field_name, creator_method = field_info

        details_obj.send("#{field_name}=", send(creator_method, @details[detail_key])) if @details.key?(detail_key)
      end
    end

    # Simplified methods for each transportation type
    def apply_public_transport_details(transportation)
      return unless @details[:walking_time_to_station]

      transport_details = Com::Igeolise::Traveltime::Rabbitmq::Requests::PublicTransportDetails.new
      set_optional_fields(
        transport_details, {
          walking_time_to_station: %i[walkingTimeToStation create_positive_uint32]
        }
      )

      transportation.publicTransport = transport_details
    end

    def apply_driving_pt_details(transportation)
      return unless need_driving_pt_details?

      transport_details = Com::Igeolise::Traveltime::Rabbitmq::Requests::DrivingAndPublicTransportDetails.new
      set_optional_fields(
        transport_details, {
          walking_time_to_station: %i[walkingTimeToStation create_positive_uint32],
          driving_time_to_station: %i[drivingTimeToStation create_positive_uint32],
          parking_time: %i[parkingTime create_non_negative_uint32]
        }
      )

      transportation.drivingAndPublicTransport = transport_details
    end

    def need_driving_pt_details?
      @details[:walking_time_to_station] ||
        @details[:driving_time_to_station] ||
        @details.key?(:parking_time)
    end
  end
end
