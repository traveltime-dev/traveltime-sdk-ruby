# frozen_string_literal: true

require 'travel_time/proto/v2/RequestsCommon_pb'
require 'travel_time/proto/v2/TimeFilterFastRequest_pb'
require 'travel_time/proto/v2/TimeFilterFastResponse_pb'

module TravelTime
  # Utilities for encoding/decoding protobuf requests
  class ProtoUtils
    def self.encode_fixed_point(source, target)
      ((target - source) * 10.pow(5)).round
    end

    def self.build_deltas(departure, destinations)
      deltas = destinations.map do |destination|
        [encode_fixed_point(departure[:lat], destination[:lat]),
         encode_fixed_point(departure[:lng], destination[:lng])]
      end
      deltas.flatten
    end

    def self.get_proto_transport_code(transport)
      proto_transport_map = {
        pt: 0,
        'driving+ferry': 3,
        'cycling+ferry': 6,
        'walking+ferry': 7
      }
      proto_transport_map[transport.to_sym]
    end

    def self.make_one_to_many(origin, destinations, transport, traveltime, properties)
      Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest::OneToMany.new(
        departureLocation: origin,
        locationDeltas: build_deltas(origin, destinations),
        transportation: Com::Igeolise::Traveltime::Rabbitmq::Requests::Transportation.new(
          { type: get_proto_transport_code(transport) }
        ),
        arrivalTimePeriod: 0,
        travelTime: traveltime,
        properties: properties
      )
    end

    def self.make_proto_message(origin, destinations, transport, traveltime, properties: nil)
      Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest.new(
        oneToManyRequest: make_one_to_many(origin, destinations, transport, traveltime, properties)
      )
    end

    def self.encode_proto_message(message)
      Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest.encode(message)
    end

    def self.decode_proto_response(response)
      Com::Igeolise::Traveltime::Rabbitmq::Responses::TimeFilterFastResponse.decode(response).to_h
    end
  end
end
