# frozen_string_literal: true

require 'faraday'
require 'travel_time/middleware/authentication'
require 'travel_time/middleware/proto'
require 'travel_time/transport'
require 'limiter'

module TravelTime
  # The Client class provides the main interface to interact with the TravelTime API
  class Client # rubocop:disable Metrics/ClassLength
    include Dry::Configurable
    extend Limiter::Mixin

    API_BASE_URL = 'https://api.traveltimeapp.com/v4/'
    PROTO_BASE_URL = 'https://proto.api.traveltimeapp.com/api/v3/'

    TravelTime.settings.each do |s|
      if s.default.nil?
        setting s.name
      else
        setting s.name, default: s.default
      end
    end

    attr_reader :connection, :proto_connection

    def initialize(rate_limit = nil)
      init_connection
      init_proto_connection

      return unless rate_limit

      %i[perform_request perform_request_proto].each do |method_name|
        self.class.limit_method method_name, balanced: true, rate: rate_limit
      end
    end

    # Instance configuration starts as a copy of the global config, so settings not
    # overridden in the block keep their globally configured values. Connections are
    # rebuilt afterwards so the new config takes effect.
    def configure
      inherit_global_config unless @instance_configured
      super.tap do
        @instance_configured = true
        init_connection
        init_proto_connection
      end
    end

    def effective_config
      @instance_configured ? config : TravelTime.config
    end

    def inherit_global_config
      TravelTime.settings.each do |s|
        config.public_send(:"#{s.name}=", TravelTime.config.public_send(s.name))
      end
    end
    private :inherit_global_config

    def init_connection
      cfg = effective_config
      @connection = Faraday.new(API_BASE_URL) do |f|
        f.request :json
        f.response :raise_error if cfg.raise_on_failure
        f.response :logger if cfg.enable_logging
        f.response :json
        f.use TravelTime::Middleware::Authentication, config: cfg
        f.adapter cfg.http_adapter || Faraday.default_adapter
      end
    end

    def init_proto_connection
      cfg = effective_config
      @proto_connection = Faraday.new do |f|
        f.response :raise_error if cfg.raise_on_failure
        f.response :logger if cfg.enable_logging
        f.use TravelTime::Middleware::ProtoMiddleware, config: cfg
        f.adapter cfg.http_adapter || Faraday.default_adapter
      end
    end

    def proto_properties(with_fares, with_distance)
      property_enum = Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest::Property
      properties = []
      properties << property_enum::FARES if with_fares
      properties << property_enum::DISTANCES if with_distance
      properties.empty? ? nil : properties
    end
    private :proto_properties

    def unwrap(response)
      Response.from_object(response)
    end

    def unwrap_proto(response, decoder: nil)
      Response.from_object_proto(response, decoder: decoder)
    end

    def perform_request
      unwrap(yield)
    rescue Faraday::Error => e
      raise TravelTime::Error.new(response: Response.from_hash(e.response), exception: e) if e.response

      raise TravelTime::Error.new(exception: e)
    rescue StandardError => e
      raise TravelTime::Error.new(exception: e)
    end

    def perform_request_proto(decoder: nil)
      unwrap_proto(yield, decoder: decoder)
    rescue Faraday::Error => e
      raise TravelTime::Error.new(response: Response.from_proto_error(e.response), exception: e) if e.response

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

    def geocoding(query:, within_country: nil, format_name: nil, exclude: nil, limit: nil, force_postcode: nil,
                  bounds: nil, accept_language: nil)
      query = {
        query: query,
        'within.country': within_country.is_a?(Array) ? within_country.join(',') : within_country,
        'format.name': format_name,
        'format.exclude.country': exclude,
        limit: limit,
        'force.add.postcode': force_postcode,
        bounds: bounds&.join(',')
      }.compact
      perform_request { connection.get('geocoding/search', query, { 'Accept-Language' => accept_language }) }
    end

    def reverse_geocoding(lat:, lng:, accept_language: nil)
      query = {
        lat: lat,
        lng: lng
      }.compact
      perform_request { connection.get('geocoding/reverse', query, { 'Accept-Language' => accept_language }) }
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

    def distance_map(departure_searches: nil, arrival_searches: nil, unions: nil, intersections: nil, format: nil)
      payload = {
        departure_searches: departure_searches,
        arrival_searches: arrival_searches,
        unions: unions,
        intersections: intersections
      }.compact
      perform_request { connection.post('distance-map', payload, { 'Accept' => format }) }
    end

    def time_map_fast(arrival_searches:, unions: nil, intersections: nil, format: nil)
      payload = {
        arrival_searches: arrival_searches,
        unions: unions,
        intersections: intersections
      }.compact
      perform_request { connection.post('time-map/fast', payload, { 'Accept' => format }) }
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
      payload = {
        locations: locations,
        arrival_searches: arrival_searches
      }.compact
      perform_request { connection.post('time-filter/fast', payload) }
    end

    def time_filter_fast_proto(country:, origin:, destinations:, transport:, traveltime:, with_distance: false,
                               with_fares: false, request_type: nil)
      transport_obj = Transport.new(transport)
      properties = proto_properties(with_fares, with_distance)
      message = ProtoUtils.make_proto_message(origin, destinations, transport_obj, traveltime,
                                              properties: properties, request_type: request_type)
      payload = ProtoUtils.encode_proto_message(message)
      path = "#{PROTO_BASE_URL}#{country.to_s.downcase}/time-filter/fast/#{transport_obj.url_name}"
      perform_request_proto { proto_connection.post(path, payload) }
    end

    def geohash_fast_proto(country:, origin:, transport:, traveltime:, resolution:, properties: nil,
                           remove_water_bodies: nil, request_type: nil)
      requests = Com::Igeolise::Traveltime::Rabbitmq::Requests
      responses = Com::Igeolise::Traveltime::Rabbitmq::Responses
      cell_fast_proto(requests::GeohashFastRequest, responses::GeohashFastResponse, 'geohash', country, origin,
                      transport, traveltime, resolution: resolution, properties: properties,
                                             remove_water_bodies: remove_water_bodies, request_type: request_type)
    end

    def h3_fast_proto(country:, origin:, transport:, traveltime:, resolution:, properties: nil,
                      remove_water_bodies: nil, request_type: nil)
      requests = Com::Igeolise::Traveltime::Rabbitmq::Requests
      responses = Com::Igeolise::Traveltime::Rabbitmq::Responses
      response = cell_fast_proto(requests::H3FastRequest, responses::H3FastResponse, 'h3', country, origin,
                                 transport, traveltime, resolution: resolution, properties: properties,
                                                        remove_water_bodies: remove_water_bodies,
                                                        request_type: request_type)
      response.body.dig(:cells, :ids)&.map! { |id| format('%x', id) }
      response
    end

    def cell_fast_proto(request_klass, response_klass, endpoint, country, origin, transport, traveltime, options)
      transport_obj = Transport.new(transport)
      message = ProtoUtils.make_cell_proto_message(request_klass, origin, transport_obj, traveltime, options)
      payload = request_klass.encode(message)
      path = "#{PROTO_BASE_URL}#{country.to_s.downcase}/#{endpoint}/fast/#{transport_obj.url_name}"
      decoder = ->(body) { response_klass.decode(body).to_h }
      perform_request_proto(decoder: decoder) { proto_connection.post(path, payload) }
    end
    private :cell_fast_proto

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

    def h3(resolution:, properties:, departure_searches: nil, arrival_searches: nil, unions: nil, intersections: nil)
      payload = {
        resolution: resolution,
        properties: properties,
        departure_searches: departure_searches,
        arrival_searches: arrival_searches,
        unions: unions,
        intersections: intersections
      }.compact
      perform_request { connection.post('h3', payload) }
    end

    def h3_fast(resolution:, properties:, arrival_searches:, unions: nil, intersections: nil)
      payload = {
        resolution: resolution,
        properties: properties,
        arrival_searches: arrival_searches,
        unions: unions,
        intersections: intersections
      }.compact
      perform_request { connection.post('h3/fast', payload) }
    end

    def geohash(resolution:, properties:, departure_searches: nil, arrival_searches: nil, unions: nil,
                intersections: nil)
      payload = {
        resolution: resolution,
        properties: properties,
        departure_searches: departure_searches,
        arrival_searches: arrival_searches,
        unions: unions,
        intersections: intersections
      }.compact
      perform_request { connection.post('geohash', payload) }
    end

    def geohash_fast(resolution:, properties:, arrival_searches:, unions: nil, intersections: nil)
      payload = {
        resolution: resolution,
        properties: properties,
        arrival_searches: arrival_searches,
        unions: unions,
        intersections: intersections
      }.compact
      perform_request { connection.post('geohash/fast', payload) }
    end
  end
end
