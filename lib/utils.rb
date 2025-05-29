# frozen_string_literal: true

require 'RequestsCommon_pb'
require 'TimeFilterFastRequest_pb'
require 'TimeFilterFastResponse_pb'

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

    def self.make_one_to_many(origin, destinations, transport_obj, traveltime, properties)
      transportation = Com::Igeolise::Traveltime::Rabbitmq::Requests::Transportation.new
      transport_obj.apply_to_proto(transportation)
      Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest::OneToMany.new(
        departureLocation: origin,
        locationDeltas: build_deltas(origin, destinations),
        transportation: transportation,
        arrivalTimePeriod: 0,
        travelTime: traveltime,
        properties: properties
      )
    end

    def self.make_proto_message(origin, destinations, transport_obj, traveltime, properties: nil)
      Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest.new(
        oneToManyRequest: make_one_to_many(origin, destinations, transport_obj, traveltime, properties)
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
