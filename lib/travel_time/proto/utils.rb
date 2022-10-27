# frozen_string_literal: true

module TravelTime
  # The Response class represent an API response.
  class ProtoUtils
    def self.encode_fixed_poiunt(source, target)
      ((target - source) * 10.pow(5)).round
    end

    def self.build_deltas(departure, destinations)
      deltas = destinations.map do |destination|
        [encode_fixed_poiunt(departure[:lat], destination[:lat]),
         encode_fixed_poiunt(departure[:lng], destination[:lng])]
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
  end
end
