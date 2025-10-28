# frozen_string_literal: true

RSpec.describe TravelTime::ProtoUtils do
  let(:utils) { described_class }
  let(:transport) { TravelTime::Transport.new('pt') }
  let(:traveltime) { 3600 }

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

  describe '.make_one_to_many' do
    it 'creates OneToMany proto message' do
      origin = { lat: 51.508930, lng: -0.131387 }
      destinations = [{ lat: 51.508824, lng: -0.167093 }]

      message = utils.make_one_to_many(origin, destinations, transport, traveltime, nil)

      expect(message).to be_a(Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest::OneToMany)
      expect(message.departureLocation.lat).to be_within(0.0001).of(origin[:lat])
      expect(message.departureLocation.lng).to be_within(0.0001).of(origin[:lng])
      expect(message.locationDeltas).to eq([-11, -3571])
      expect(message.travelTime).to eq(traveltime)
    end
  end

  describe '.make_many_to_one' do
    it 'creates ManyToOne proto message' do
      arrival = { lat: 51.508930, lng: -0.131387 }
      origins = [{ lat: 51.508824, lng: -0.167093 }]

      message = utils.make_many_to_one(arrival, origins, transport, traveltime, nil)

      expect(message).to be_a(Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest::ManyToOne)
      expect(message.arrivalLocation.lat).to be_within(0.0001).of(arrival[:lat])
      expect(message.arrivalLocation.lng).to be_within(0.0001).of(arrival[:lng])
      expect(message.locationDeltas).to eq([-11, -3571])
      expect(message.travelTime).to eq(traveltime)
    end
  end

  describe '.make_proto_message' do
    let(:origin) { { lat: 51.508930, lng: -0.131387 } }
    let(:destinations) { [{ lat: 51.508824, lng: -0.167093 }] }

    it 'creates proto message with ONE_TO_MANY by default' do
      message = utils.make_proto_message(origin, destinations, transport, traveltime)

      expect(message).to be_a(Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest)
      expect(message.oneToManyRequest).not_to be_nil
      expect(message.manyToOneRequest).to be_nil
    end

    it 'creates proto message with MANY_TO_ONE when specified' do
      message = utils.make_proto_message(origin, destinations, transport, traveltime, request_type: TravelTime::ProtoUtils::MANY_TO_ONE)

      expect(message).to be_a(Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest)
      expect(message.manyToOneRequest).not_to be_nil
      expect(message.oneToManyRequest).to be_nil
    end

    it 'raises error for invalid request_type' do
      expect do
        utils.make_proto_message(origin, destinations, transport, traveltime, request_type: :invalid)
      end.to raise_error(ArgumentError, /Invalid request_type/)
    end
  end
end
