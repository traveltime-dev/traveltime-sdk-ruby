# frozen_string_literal: true

RSpec.describe TravelTime::Client do
  let(:client) { described_class.new }
  let(:connection) { client.connection }
  let(:rate_limit) { 10 }

  it 'defaults to API v4' do
    expect(described_class::API_BASE_URL).to end_with('v4/')
  end

  it 'manages authentication' do
    expect(connection.builder.handlers).to include(TravelTime::Middleware::Authentication)
  end

  describe 'connection adapter' do
    context 'with default config' do
      let(:expected) { Faraday::Adapter.lookup_middleware(Faraday.default_adapter) }

      it 'defaults to Faraday.default_adapter' do
        expect(connection.adapter).to eq(expected)
      end
    end

    context 'with custom http_adapter config' do
      before { TravelTime.config.http_adapter = :test }

      it 'uses the configured adapter' do
        expect(connection.adapter).to eq(Faraday::Adapter::Test)
      end
    end
  end

  describe 'logging' do
    context 'with default config' do
      it 'does not use the logging middleware' do
        expect(connection.builder.handlers).not_to include(Faraday::Response::Logger)
      end
    end

    context 'with enable_logging config set to true' do
      before { TravelTime.config.enable_logging = true }

      it 'does not use the logging middleware' do
        expect(connection.builder.handlers).to include(Faraday::Response::Logger)
      end
    end
  end

  describe 'raise_on_failure' do
    context 'with default config' do
      it 'does not use the raise_error middleware' do
        expect(connection.builder.handlers).not_to include(Faraday::Response::RaiseError)
      end
    end

    context 'with raise_on_failure config set to true' do
      before { TravelTime.config.raise_on_failure = true }

      it 'does not use the raise_error middleware' do
        expect(connection.builder.handlers).to include(Faraday::Response::RaiseError)
      end
    end
  end

  describe 'API Endpoints' do
    before { stub }

    describe '#map_info' do
      subject(:response) { client.map_info }

      let(:url) { "#{described_class::API_BASE_URL}map-info" }
      let(:stub) { stub_request(:get, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#supported_locations' do
      subject(:response) { client.supported_locations(locations: []) }

      let(:url) { "#{described_class::API_BASE_URL}supported-locations" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#geocoding' do
      subject(:response) { client.geocoding(query: 'London') }

      let(:url) { "#{described_class::API_BASE_URL}geocoding/search" }
      let(:stub) { stub_request(:get, url).with(query: { query: 'London' }) }

      it_behaves_like 'an endpoint method'
    end

    describe '#reverse_geocoding' do
      subject(:response) { client.reverse_geocoding(lat: 51.507281, lng: -0.132120) }

      let(:url) { "#{described_class::API_BASE_URL}geocoding/reverse" }
      let(:stub) { stub_request(:get, url).with(query: { lat: 51.507281, lng: -0.132120 }) }

      it_behaves_like 'an endpoint method'
    end

    describe '#time_map' do
      subject(:response) { client.time_map }

      let(:url) { "#{described_class::API_BASE_URL}time-map" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#distance_map' do
      subject(:response) { client.distance_map }

      let(:url) { "#{described_class::API_BASE_URL}distance-map" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#time_map_fast' do
      subject(:response) { client.time_map_fast(arrival_searches: []) }

      let(:url) { "#{described_class::API_BASE_URL}time-map/fast" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#time_filter' do
      subject(:response) { client.time_filter(locations: []) }

      let(:url) { "#{described_class::API_BASE_URL}time-filter" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#time_filter_fast' do
      subject(:response) { client.time_filter_fast(locations: [], arrival_searches: []) }

      let(:url) { "#{described_class::API_BASE_URL}time-filter/fast" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#time_filter_fast_proto' do
      country = 'uk'
      transport = 'pt'
      subject(:response) do
        client.time_filter_fast_proto(country: country, origin: {}, destinations: {}, transport: transport,
                                      traveltime: 0)
      end

      let(:url) { "http://proto.api.traveltimeapp.com/api/v2/#{country}/time-filter/fast/#{transport}" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#time_filter_fast_proto_distance' do
      country = 'uk'
      transport = 'driving+ferry'
      subject(:response) do
        client.time_filter_fast_proto_distance(country: country, origin: {}, destinations: {}, transport: transport,
                                               traveltime: 0)
      end

      let(:url) { "https://proto-with-distance.api.traveltimeapp.com/api/v2/#{country}/time-filter/fast/#{transport}" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#time_filter_postcodes' do
      subject(:response) { client.time_filter_postcodes(arrival_searches: []) }

      let(:url) { "#{described_class::API_BASE_URL}time-filter/postcodes" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#time_filter_postcode_districts' do
      subject(:response) { client.time_filter_postcode_districts(arrival_searches: []) }

      let(:url) { "#{described_class::API_BASE_URL}time-filter/postcode-districts" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#time_filter_postcode_sectors' do
      subject(:response) { client.time_filter_postcode_sectors(arrival_searches: []) }

      let(:url) { "#{described_class::API_BASE_URL}time-filter/postcode-sectors" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#routes' do
      subject(:response) { client.routes(locations: []) }

      let(:url) { "#{described_class::API_BASE_URL}routes" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end
  end

  describe 'Rate limiter' do
    context 'when rate_limit is provided' do
      let(:client) { described_class.new(rate_limit) }

      it 'calls limit_method with correct params' do
        allow(described_class).to receive(:limit_method)
        client
        expect(described_class).to have_received(:limit_method).with(:perform_request, balanced: true, rate: rate_limit)
      end
    end

    context 'when rate_limit is not provided' do
      let(:client) { described_class.new }

      it 'does not call limit_method' do
        allow(described_class).to receive(:limit_method)

        client

        expect(described_class).not_to have_received(:limit_method)
      end
    end
  end
end
