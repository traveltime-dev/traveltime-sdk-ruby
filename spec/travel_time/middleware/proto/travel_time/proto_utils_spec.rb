# frozen_string_literal: true

RSpec.describe TravelTime::ProtoUtils do
  let(:utils) { described_class }

  describe '.encode_fixed_point' do
    it 'calculates fixed point correctly' do
      expected = -11
      departure_lat = 51.508930
      destination_lat = 51.508824
      expect(utils.encode_fixed_point(departure_lat, destination_lat)).to eq(expected)
    end

    it 'builds deltas correctly' do
      expected = [-11, -3571]
      departure = { lat: 51.508930, lng: -0.131387 }
      destinations = [{ lat: 51.508824, lng: -0.167093 }]
      expect(utils.build_deltas(departure, destinations)).to eq(expected)
    end
  end
end
