# frozen_string_literal: true

RSpec.describe TravelTime::Transport do
  let(:proto_utils) { TravelTime::ProtoUtils }
  # Stub the dependency. allow makes it a "spy"
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
    # Create a real Transportation object instead of a double
    let(:transportation) { Com::Igeolise::Traveltime::Rabbitmq::Requests::Transportation.new }
    let(:pt_details_class) { Com::Igeolise::Traveltime::Rabbitmq::Requests::PublicTransportDetails }
    let(:driving_pt_details_class) { Com::Igeolise::Traveltime::Rabbitmq::Requests::DrivingAndPublicTransportDetails }

    context 'with pt transport and walking_time_to_station' do
      subject(:transport) { described_class.new(type: 'pt', walking_time_to_station: 600) }

      let(:expected_pt_details) do
        {
          class: pt_details_class,
          walkingTimeToStation: 600
        }
      end

      it 'sets the type on transportation' do
        result = transport.apply_to_proto(transportation)
        expect(result.type).to eq(:PUBLIC_TRANSPORT)
      end

      it 'sets PublicTransportDetails correctly' do
        result = transport.apply_to_proto(transportation)
        expect(result.publicTransport).to have_attributes(expected_pt_details)
      end
    end

    context 'with pt transport but no details' do
      subject(:transport) { described_class.new('pt') }

      it 'sets the type on transportation' do
        result = transport.apply_to_proto(transportation)
        expect(result.type).to eq(:PUBLIC_TRANSPORT)
      end

      it 'does not set PublicTransportDetails' do
        result = transport.apply_to_proto(transportation)
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
      let(:expected_driving_pt_details) do
        {
          class: driving_pt_details_class,
          walkingTimeToStation: 600,
          drivingTimeToStation: 1200,
          parkingTime: 300
        }
      end

      before do
        allow(proto_utils).to receive(:get_proto_transport_info)
          .with('driving+pt')
          .and_return({ code: 2, url_name: 'driving+pt' })
      end

      it 'sets the type on transportation' do
        result = transport.apply_to_proto(transportation)
        expect(result.type).to eq(:DRIVING_AND_PUBLIC_TRANSPORT)
      end

      it 'sets all details on DrivingAndPublicTransportDetails' do
        result = transport.apply_to_proto(transportation)
        expect(result.drivingAndPublicTransport).to have_attributes(expected_driving_pt_details)
      end
    end

    context 'with driving+pt transport and partial details' do
      subject(:transport) { described_class.new(type: 'driving+pt', driving_time_to_station: 1200) }

      let(:expected_partial_driving_pt_details) do
        {
          class: driving_pt_details_class,
          drivingTimeToStation: 1200,
          walkingTimeToStation: 0, # Assuming 0 is the proto default for unset integers
          parkingTime: 0           # Assuming 0 is the proto default for unset integers
        }
      end

      before do
        allow(proto_utils).to receive(:get_proto_transport_info)
          .with('driving+pt')
          .and_return({ code: 2, url_name: 'driving+pt' })
      end

      it 'sets only provided details, with others as default' do
        result = transport.apply_to_proto(transportation)
        expect(result.drivingAndPublicTransport).to have_attributes(expected_partial_driving_pt_details)
      end
    end

    context 'with driving+pt transport but no details' do
      subject(:transport) { described_class.new('driving+pt') }

      before do
        allow(proto_utils).to receive(:get_proto_transport_info)
          .with('driving+pt')
          .and_return({ code: 2, url_name: 'driving+pt' })
      end

      it 'sets the type on transportation' do
        result = transport.apply_to_proto(transportation)
        expect(result.type).to eq(:DRIVING_AND_PUBLIC_TRANSPORT)
      end

      it 'does not set DrivingAndPublicTransportDetails' do
        result = transport.apply_to_proto(transportation)
        expect(result.drivingAndPublicTransport).to be_nil
      end
    end

    context 'with other transport types' do
      subject(:transport) { described_class.new('driving+ferry') }

      before do
        allow(proto_utils).to receive(:get_proto_transport_info)
          .with('driving+ferry')
          .and_return({ code: 3, url_name: 'driving+ferry' })
      end

      it 'sets the type on transportation' do
        result = transport.apply_to_proto(transportation)
        expect(result.type).to eq(:DRIVING_AND_FERRY)
      end

      # Split into two tests, fixing MultipleExpectations
      it 'does not create publicTransport details' do
        result = transport.apply_to_proto(transportation)
        expect(result.publicTransport).to be_nil
      end

      it 'does not create drivingAndPublicTransport details' do
        result = transport.apply_to_proto(transportation)
        expect(result.drivingAndPublicTransport).to be_nil
      end
    end
  end

  # Removed the describe block for the private method.
  # Its behaviour is implicitly covered by the #apply_to_proto tests,
  # which is a more robust, less brittle way to test.
end
