# frozen_string_literal: true

RSpec.describe TravelTime::Transport do
  let(:proto_utils) { TravelTime::ProtoUtils }
  let(:transport_info) { { code: 0, url_name: 'pt' } }

  before do
    allow(proto_utils).to receive(:get_proto_transport_info).with(any_args).and_return(transport_info)
  end

  describe '#initialize' do
    context 'with string input' do
      subject(:transport) { described_class.new('pt') }

      it 'sets type to the string value' do
        expect(transport.type).to eq('pt')
      end

      it 'sets details to an empty hash' do
        expect(transport.details).to eq({})
      end

      it 'sets code from transport map' do
        expect(transport.code).to eq(0)
      end

      it 'sets url_name from transport map' do
        expect(transport.url_name).to eq('pt')
      end
    end

    context 'with hash input' do
      subject(:transport) { described_class.new(transport_options) }

      let(:transport_options) { { type: 'pt', walking_time_to_station: 600 } }

      it 'sets type to the type value from the hash' do
        expect(transport.type).to eq('pt')
      end

      it 'sets details to the hash without type key' do
        expect(transport.details).to eq(walking_time_to_station: 600)
      end

      context 'when validation fails' do
        let(:invalid_transport_options) { { type: 'pt', parking_time: 300 } } # Invalid detail for 'pt'

        it 'raises an ArgumentError during initialization' do
          expected_message = "Unexpected details for transport type 'pt': parking_time. " \
                             'Allowed: walking_time_to_station'
          expect { described_class.new(invalid_transport_options) }
            .to raise_error(ArgumentError, expected_message)
        end
      end
    end
  end

  describe '#validate_details!' do
    context 'with empty details' do
      subject(:transport) { described_class.new('pt') }

      it 'returns nil' do
        expect { transport.validate_details! }.not_to raise_error
      end
    end

    context 'with transport type that does not support details' do
      subject(:transport) { described_class.allocate }

      let(:details) { { walking_time_to_station: 600 } }

      before do
        transport.instance_variable_set(:@type, 'driving+ferry')
        transport.instance_variable_set(:@details, details)
      end

      it 'raises ArgumentError with appropriate message' do
        expected_message = "Transport type 'driving+ferry' doesn't support additional details, " \
                           "but #{details.keys.join(', ')} provided"
        expect { transport.validate_details! }.to raise_error(ArgumentError, expected_message)
      end
    end

    context 'with unexpected details for transport type' do
      subject(:transport) { described_class.allocate }

      let(:details) { { parking_time: 300 } }

      before do
        transport.instance_variable_set(:@type, 'pt')
        transport.instance_variable_set(:@details, details)
      end

      it 'raises ArgumentError with appropriate message' do
        expected_message = "Unexpected details for transport type 'pt': parking_time. " \
                           'Allowed: walking_time_to_station'
        expect { transport.validate_details! }.to raise_error(ArgumentError, expected_message)
      end
    end

    context 'with valid details for transport type' do
      subject(:transport) { described_class.new(type: 'pt', walking_time_to_station: 600) }

      it 'does not raise an error' do
        expect { transport.validate_details! }.not_to raise_error
      end
    end

    context 'with multiple valid details for transport type' do
      subject(:transport) { described_class.new(transport_options) }

      let(:transport_options) do
        {
          type: 'driving+pt',
          walking_time_to_station: 600,
          driving_time_to_station: 1200,
          parking_time: 300
        }
      end

      before do
        allow(proto_utils).to receive(:get_proto_transport_info)
          .with('driving+pt')
          .and_return({ code: 2, url_name: 'driving+pt' })
      end

      it 'does not raise an error' do
        expect { transport.validate_details! }.not_to raise_error
      end
    end
  end

  describe '#apply_to_proto' do
    let(:transportation) { Com::Igeolise::Traveltime::Rabbitmq::Requests::Transportation.new }
    let(:pt_details_class) { Com::Igeolise::Traveltime::Rabbitmq::Requests::PublicTransportDetails }
    let(:driving_pt_details_class) { Com::Igeolise::Traveltime::Rabbitmq::Requests::DrivingAndPublicTransportDetails }
    let(:positive_uint32_class) { Com::Igeolise::Traveltime::Rabbitmq::Requests::OptionalPositiveUInt32 }
    let(:non_negative_uint32_class) { Com::Igeolise::Traveltime::Rabbitmq::Requests::OptionalNonNegativeUInt32 }

    context 'with pt transport and walking_time_to_station' do
      subject(:transport) { described_class.new(type: 'pt', walking_time_to_station: 600) }

      let(:result) { transport.apply_to_proto(transportation) }

      it 'sets the type on transportation' do
        expect(result.type).to eq(:PUBLIC_TRANSPORT)
      end

      it 'sets PublicTransportDetails with the correct class' do
        expect(result.publicTransport).to be_a(pt_details_class)
      end

      it 'sets walkingTimeToStation with the correct type' do
        expect(result.publicTransport.walkingTimeToStation).to be_a(positive_uint32_class)
      end

      it 'sets walkingTimeToStation with the correct value' do
        expect(result.publicTransport.walkingTimeToStation.value).to eq(600)
      end
    end

    context 'with pt transport but no details' do
      subject(:transport) { described_class.new('pt') }

      let(:result) { transport.apply_to_proto(transportation) }

      it 'sets the type on transportation' do
        expect(result.type).to eq(:PUBLIC_TRANSPORT)
      end

      it 'does not set PublicTransportDetails' do
        expect(result.publicTransport).to be_nil
      end
    end

    context 'with driving+pt transport and all details' do
      subject(:transport) { described_class.new(transport_options) }

      let(:transport_options) do
        {
          type: 'driving+pt',
          walking_time_to_station: 600,
          driving_time_to_station: 1200,
          parking_time: 300
        }
      end

      let(:result) { transport.apply_to_proto(transportation) }

      before do
        allow(proto_utils).to receive(:get_proto_transport_info)
          .with('driving+pt')
          .and_return({ code: 2, url_name: 'driving+pt' })
      end

      it 'sets the type on transportation' do
        expect(result.type).to eq(:DRIVING_AND_PUBLIC_TRANSPORT)
      end

      it 'sets DrivingAndPublicTransportDetails with the correct class' do
        expect(result.drivingAndPublicTransport).to be_a(driving_pt_details_class)
      end

      it 'sets walkingTimeToStation with the correct type' do
        expect(result.drivingAndPublicTransport.walkingTimeToStation).to be_a(positive_uint32_class)
      end

      it 'sets walkingTimeToStation with the correct value' do
        expect(result.drivingAndPublicTransport.walkingTimeToStation.value).to eq(600)
      end

      it 'sets drivingTimeToStation with the correct type' do
        expect(result.drivingAndPublicTransport.drivingTimeToStation).to be_a(positive_uint32_class)
      end

      it 'sets drivingTimeToStation with the correct value' do
        expect(result.drivingAndPublicTransport.drivingTimeToStation.value).to eq(1200)
      end

      it 'sets parkingTime with the correct type' do
        expect(result.drivingAndPublicTransport.parkingTime).to be_a(non_negative_uint32_class)
      end

      it 'sets parkingTime with the correct value' do
        expect(result.drivingAndPublicTransport.parkingTime.value).to eq(300)
      end
    end

    context 'with driving+pt transport and partial details' do
      subject(:transport) { described_class.new(type: 'driving+pt', driving_time_to_station: 1200) }

      let(:result) { transport.apply_to_proto(transportation) }

      before do
        allow(proto_utils).to receive(:get_proto_transport_info)
          .with('driving+pt')
          .and_return({ code: 2, url_name: 'driving+pt' })
      end

      it 'sets DrivingAndPublicTransportDetails with the correct class' do
        expect(result.drivingAndPublicTransport).to be_a(driving_pt_details_class)
      end

      it 'sets drivingTimeToStation with the correct type' do
        expect(result.drivingAndPublicTransport.drivingTimeToStation).to be_a(positive_uint32_class)
      end

      it 'sets drivingTimeToStation with the correct value' do
        expect(result.drivingAndPublicTransport.drivingTimeToStation.value).to eq(1200)
      end

      it 'does not set walkingTimeToStation' do
        expect(result.drivingAndPublicTransport.walkingTimeToStation).to be_nil
      end

      it 'does not set parkingTime' do
        expect(result.drivingAndPublicTransport.parkingTime).to be_nil
      end
    end

    context 'with driving+pt transport but no details' do
      subject(:transport) { described_class.new('driving+pt') }

      let(:result) { transport.apply_to_proto(transportation) }

      before do
        allow(proto_utils).to receive(:get_proto_transport_info)
          .with('driving+pt')
          .and_return({ code: 2, url_name: 'driving+pt' })
      end

      it 'sets the type on transportation' do
        expect(result.type).to eq(:DRIVING_AND_PUBLIC_TRANSPORT)
      end

      it 'does not set DrivingAndPublicTransportDetails' do
        expect(result.drivingAndPublicTransport).to be_nil
      end
    end

    context 'with other transport types' do
      subject(:transport) { described_class.new('driving+ferry') }

      let(:result) { transport.apply_to_proto(transportation) }

      before do
        allow(proto_utils).to receive(:get_proto_transport_info)
          .with('driving+ferry')
          .and_return({ code: 3, url_name: 'driving+ferry' })
      end

      it 'sets the type on transportation' do
        expect(result.type).to eq(:DRIVING_AND_FERRY)
      end

      it 'does not create publicTransport details' do
        expect(result.publicTransport).to be_nil
      end

      it 'does not create drivingAndPublicTransport details' do
        expect(result.drivingAndPublicTransport).to be_nil
      end
    end
  end
end
