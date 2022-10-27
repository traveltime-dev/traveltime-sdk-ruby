# frozen_string_literal: true

require 'faraday'
require 'google/protobuf'
require 'travel_time/middleware/authentication'
require 'travel_time/middleware/proto'
require 'travel_time/proto/utils'
require 'travel_time/proto/v2/TimeFilterFastRequest_pb'
require 'travel_time/proto/v2/TimeFilterFastResponse_pb'
require 'travel_time/proto/v2/RequestsCommon_pb'

module TravelTime
  # The Client class provides the main interface to interact with the TravelTime API
  class Client # rubocop:disable Metrics/ClassLength
    API_BASE_URL = 'https://api.traveltimeapp.com/v4/'

    attr_reader :connection

    def initialize
      @connection = Faraday.new(API_BASE_URL) do |f|
        f.request :json
        f.response :raise_error if TravelTime.config.raise_on_failure
        f.response :logger if TravelTime.config.enable_logging
        f.response :json
        f.use TravelTime::Middleware::Authentication
        f.adapter TravelTime.config.http_adapter || Faraday.default_adapter
      end
    end

    def unwrap(response)
      Response.from_object(response)
    end

    def perform_request
      unwrap(yield)
    rescue Faraday::Error => e
      raise TravelTime::Error.new(response: Response.from_hash(e.response)) if e.response

      raise TravelTime::Error.new(exception: e)
    rescue StandardError => e
      raise TravelTime::Error.new(exception: e)
    end

    def map_info
      perform_request { connection.get('map-info') }
    end

    def supported_locations(locations:)
      perform_request { connection.post('supported-locations', { locations: locations }) }
    end

    def geocoding(query:, within_country: nil, exclude: nil, limit: nil, force_postcode: nil, bounds: nil)
      query = {
        query: query,
        'within.country': within_country,
        'exclude.location.types': exclude,
        limit: limit,
        'force.add.postcode': force_postcode,
        bounds: bounds ? bounds.join(',') : nil
      }.compact
      perform_request { connection.get('geocoding/search', query) }
    end

    def reverse_geocoding(lat:, lng:, within_country: nil, exclude: nil)
      query = {
        lat: lat,
        lng: lng,
        'within.country': within_country,
        'exclude.location.types': exclude
      }.compact
      perform_request { connection.get('geocoding/reverse', query) }
    end

    def time_map(departure_searches: nil, arrival_searches: nil, unions: nil, intersections: nil, format: nil)
      payload = {
        departure_searches: departure_searches,
        arrival_searches: arrival_searches,
        unions: unions,
        intersections: intersections
      }.compact
      perform_request { connection.post('time-map', payload, { 'Accept' => format }) }
    end

    def time_filter(locations:, departure_searches: nil, arrival_searches: nil)
      payload = {
        locations: locations,
        departure_searches: departure_searches,
        arrival_searches: arrival_searches
      }.compact
      perform_request { connection.post('time-filter', payload) }
    end

    def time_filter_fast(locations:, arrival_searches:)
      connection
        .payload = {
          locations: locations,
          arrival_searches: arrival_searches
        }.compact
      perform_request { connection.post('time-filter/fast', payload) }
    end

    # make :
    def time_filter_fast_proto(country, origin, destinations, transport, traveltime)
      base_uri = 'http://proto.api.traveltimeapp.com/api/v2/'
      proto_client = Faraday.new(base_uri) do |f|
        f.response :raise_error if TravelTime.config.raise_on_failure
        f.response :logger if TravelTime.config.enable_logging
        f.use TravelTime::Middleware::ProtoMiddleware
        f.adapter :net_http
      end

      message = Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest.new(
        oneToManyRequest: Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest::OneToMany.new(
          departureLocation: origin,
          locationDeltas: ProtoUtils.build_deltas(origin, destinations),
          transportation: Com::Igeolise::Traveltime::Rabbitmq::Requests::Transportation.new(
            { type: ProtoUtils.get_proto_transport_code(transport) }
          ),
          arrivalTimePeriod: 0,
          travelTime: traveltime,
          properties: nil
        )
      )

      serialized = Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest.encode(message)
      proto_response = proto_client.post("#{country}/time-filter/fast/#{transport}", serialized)
      # TODO: decode and send back as response
      Com::Igeolise::Traveltime::Rabbitmq::Responses::TimeFilterFastResponse.decode(proto_response).to_h
    end

    def time_filter_postcodes(departure_searches: nil, arrival_searches: nil)
      payload = {
        departure_searches: departure_searches,
        arrival_searches: arrival_searches
      }.compact
      perform_request { connection.post('time-filter/postcodes', payload) }
    end

    def time_filter_postcode_districts(departure_searches: nil, arrival_searches: nil)
      payload = {
        departure_searches: departure_searches,
        arrival_searches: arrival_searches
      }.compact
      perform_request { connection.post('time-filter/postcode-districts', payload) }
    end

    def time_filter_postcode_sectors(departure_searches: nil, arrival_searches: nil)
      payload = {
        departure_searches: departure_searches,
        arrival_searches: arrival_searches
      }.compact
      perform_request { connection.post('time-filter/postcode-sectors', payload) }
    end

    def routes(locations:, departure_searches: nil, arrival_searches: nil)
      payload = {
        locations: locations,
        departure_searches: departure_searches,
        arrival_searches: arrival_searches
      }.compact
      perform_request { connection.post('routes', payload) }
    end
  end
end
