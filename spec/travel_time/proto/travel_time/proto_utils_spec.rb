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
    let(:origin) { { lat: 51.508930, lng: -0.131387 } }
    let(:destinations) { [{ lat: 51.508824, lng: -0.167093 }] }
    let(:message) { utils.make_one_to_many(origin, destinations, transport, traveltime, nil) }

    it 'creates OneToMany proto message' do
      expect(message).to be_a(Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest::OneToMany)
    end

    it 'sets departure location lat correctly' do
      expect(message.departureLocation.lat).to be_within(0.001).of(origin[:lat])
    end

    it 'sets departure location lng correctly' do
      expect(message.departureLocation.lng).to be_within(0.001).of(origin[:lng])
    end

    it 'calculates location deltas correctly' do
      expect(message.locationDeltas).to eq([-11, -3571])
    end
  end

  describe '.make_many_to_one' do
    let(:arrival) { { lat: 51.508930, lng: -0.131387 } }
    let(:origins) { [{ lat: 51.508824, lng: -0.167093 }] }
    let(:message) { utils.make_many_to_one(arrival, origins, transport, traveltime, nil) }

    it 'creates ManyToOne proto message' do
      expect(message).to be_a(Com::Igeolise::Traveltime::Rabbitmq::Requests::TimeFilterFastRequest::ManyToOne)
    end

    it 'sets arrival location lat correctly' do
      expect(message.arrivalLocation.lat).to be_within(0.001).of(arrival[:lat])
    end

    it 'sets arrival location lng correctly' do
      expect(message.arrivalLocation.lng).to be_within(0.001).of(arrival[:lng])
    end

    it 'calculates location deltas correctly' do
      expect(message.locationDeltas).to eq([-11, -3571])
    end
  end

  describe '.make_proto_message' do
    let(:origin) { { lat: 51.508930, lng: -0.131387 } }
    let(:destinations) { [{ lat: 51.508824, lng: -0.167093 }] }

    context 'with ONE_TO_MANY by default' do
      let(:message) { utils.make_proto_message(origin, destinations, transport, traveltime) }

      it 'creates proto message with oneToManyRequest' do
        expect(message.oneToManyRequest).not_to be_nil
      end

      it 'does not set manyToOneRequest' do
        expect(message.manyToOneRequest).to be_nil
      end
    end

    context 'with MANY_TO_ONE specified' do
      let(:message) do
        utils.make_proto_message(origin, destinations, transport, traveltime,
                                 request_type: TravelTime::ProtoUtils::MANY_TO_ONE)
      end

      it 'creates proto message with manyToOneRequest' do
        expect(message.manyToOneRequest).not_to be_nil
      end

      it 'does not set oneToManyRequest' do
        expect(message.oneToManyRequest).to be_nil
      end
    end

    context 'with invalid request_type' do
      it 'raises ArgumentError' do
        expect do
          utils.make_proto_message(origin, destinations, transport, traveltime, request_type: :invalid)
        end.to raise_error(ArgumentError, /Invalid request_type/)
      end
    end
  end
end
