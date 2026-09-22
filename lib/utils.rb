# frozen_string_literal: true

require 'RequestsCommon_pb'
require 'TimeFilterFastRequest_pb'
require 'TimeFilterFastResponse_pb'
require 'GeohashFastRequest_pb'
require 'GeohashFastResponse_pb'
require 'H3FastRequest_pb'
require 'H3FastResponse_pb'

module TravelTime
  # Utilities for encoding/decoding protobuf requests
  class ProtoUtils
    # Request type constants
    ONE_TO_MANY = :one_to_many
    MANY_TO_ONE = :many_to_one

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

    def self.make_many_to_one(arrival, origins, transport_obj, traveltime, properties)
      transportation = Com::Igeolise::Traveltime::Rabbitmq::Requests::Transportation.new
      transport_obj.apply_to_proto(transportation)
      Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest::ManyToOne.new(
        arrivalLocation: arrival,
        locationDeltas: build_deltas(arrival, origins),
        transportation: transportation,
        arrivalTimePeriod: 0,
        travelTime: traveltime,
        properties: properties
      )
    end

    def self.make_proto_message(origin, destinations, transport_obj, traveltime, properties: nil, request_type: nil)
      request_type ||= ONE_TO_MANY
      request = Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest.new

      if request_type == ONE_TO_MANY
        request.oneToManyRequest = make_one_to_many(origin, destinations, transport_obj, traveltime, properties)
      elsif request_type == MANY_TO_ONE
        request.manyToOneRequest = make_many_to_one(origin, destinations, transport_obj, traveltime, properties)
      else
        raise ArgumentError, "Invalid request_type: #{request_type}. Must be ONE_TO_MANY or MANY_TO_ONE"
      end

      request
    end

    def self.encode_proto_message(message)
      Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest.encode(message)
    end

    def self.make_cell_search(search_klass, transport_obj, traveltime, options)
      search = search_klass.new(
        transportation: make_transportation(transport_obj),
        arrivalTimePeriod: 0,
        travelTime: traveltime,
        resolution: options[:resolution],
        properties: cell_properties(options[:properties])
      )
      search.removeWaterBodies = options[:remove_water_bodies] unless options[:remove_water_bodies].nil?
      search
    end

    def self.make_transportation(transport_obj)
      transportation = Com::Igeolise::Traveltime::Rabbitmq::Requests::Transportation.new
      transport_obj.apply_to_proto(transportation)
      transportation
    end

    def self.cell_properties(properties)
      properties&.map { |property| property.to_s.upcase.to_sym }
    end

    def self.cell_search_klass(request_klass, request_type)
      case request_type
      when ONE_TO_MANY then request_klass::OneToMany
      when MANY_TO_ONE then request_klass::ManyToOne
      else raise ArgumentError, "Invalid request_type: #{request_type}"
      end
    end

    def self.make_cell_proto_message(request_klass, origin, transport_obj, traveltime, options)
      request_type = options[:request_type] || ONE_TO_MANY
      search = make_cell_search(cell_search_klass(request_klass, request_type), transport_obj, traveltime, options)
      location = Com::Igeolise::Traveltime::Rabbitmq::Requests::Coords.new(origin)
      if request_type == ONE_TO_MANY
        search.departureLocation = location
        request_klass.new(oneToManyRequest: search)
      else
        search.arrivalLocation = location
        request_klass.new(manyToOneRequest: search)
      end
    end

    def self.decode_proto_response(response)
      Com::Igeolise::Traveltime::Rabbitmq::Responses::TimeFilterFastResponse.decode(response).to_h
    end
  end
end
