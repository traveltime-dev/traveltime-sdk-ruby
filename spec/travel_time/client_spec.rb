# frozen_string_literal: true

RSpec.describe TravelTime::Client do
  let(:client) { described_class.new }
  let(:connection) { client.connection }
  let(:rate_limit) { 10 }

  it 'defaults to API v4' do
    expect(described_class::API_BASE_URL).to end_with('v4/')
  end

  it 'uses HTTPS for the proto endpoint' do
    expect(described_class::PROTO_BASE_URL).to start_with('https://')
  end

  it 'manages authentication' do
    expect(connection.builder.handlers).to include(TravelTime::Middleware::Authentication)
  end

  it 'attaches proto credentials after the logger, so they are never logged' do
    TravelTime.config.enable_logging = true
    handlers = described_class.new.proto_connection.builder.handlers
    expect(handlers.index(TravelTime::Middleware::ProtoMiddleware))
      .to be > handlers.index(Faraday::Response::Logger)
  end

  describe 'custom credentials' do
    let(:custom_client) do
      described_class.new.configure do |config|
        config.application_id = 'CUSTOM_APP_ID'
        config.api_key = 'CUSTOM_KEY'
      end
    end

    it 'allows setting custom application_id' do
      expect(custom_client.config.application_id).to eq('CUSTOM_APP_ID')
    end

    it 'allows setting custom api_key' do
      expect(custom_client.config.api_key).to eq('CUSTOM_KEY')
    end

    it 'uses instance config when custom credentials are set' do
      custom_client = described_class.new.configure do |config|
        config.application_id = 'CUSTOM_APP_ID'
        config.api_key = 'CUSTOM_KEY'
      end
      expect(custom_client.send(:effective_config)).to eq(custom_client.config)
    end

    it 'falls back to global config when no custom credentials are set' do
      default_client = described_class.new
      expect(default_client.send(:effective_config)).to eq(TravelTime.config)
    end

    it 'inherits settings that are not overridden from the global config' do
      TravelTime.configure { |config| config.raise_on_failure = true }
      client = described_class.new.configure { |config| config.application_id = 'CUSTOM_APP_ID' }
      expect(client.send(:effective_config).raise_on_failure).to be(true)
    ensure
      TravelTime.configure { |config| config.raise_on_failure = false }
    end

    it 'rebuilds the connections when configured' do
      client = described_class.new
      expect { client.configure { |config| config.api_key = 'CUSTOM_KEY' } }
        .to change(client, :connection).and change(client, :proto_connection)
    end
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

      context 'when the API fails with a body that is not JSON' do
        let(:raised) do
          response
        rescue TravelTime::Error => e
          e
        end

        before do
          TravelTime.config.raise_on_failure = true
          stub.to_return(status: 502, body: '<html><meta name="description"></html>')
        end

        it 'keeps the underlying message rather than falling back to the default' do
          expect(raised.message).to include('502')
        end
      end
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

      let(:url) { "#{described_class::PROTO_BASE_URL}#{country}/time-filter/fast/#{transport}" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'

      context 'when the proto API reports an error' do
        let(:error_headers) do
          { 'X-ERROR-CODE' => '8', 'X-ERROR-MESSAGE' => 'Unsupported transportation mode',
            'X-ERROR-DETAILS' => 'contact support' }
        end

        before { stub.to_return(status: 400, headers: error_headers) }

        it 'surfaces the error headers on the response' do
          expect(response.body).to eq('error_code' => '8', 'description' => 'Unsupported transportation mode',
                                      'additional_info' => 'contact support')
        end

        context 'with raise_on_failure enabled' do
          let(:raised) do
            response
          rescue TravelTime::Error => e
            e
          end

          before { TravelTime.config.raise_on_failure = true }

          it 'raises an error carrying the server message' do
            expect(raised.message).to eq('Unsupported transportation mode')
          end
        end
      end

      context 'when the proto API fails without error headers' do
        let(:raised) do
          response
        rescue TravelTime::Error => e
          e
        end

        before do
          TravelTime.config.raise_on_failure = true
          stub.to_return(status: 502)
        end

        it 'keeps the underlying message rather than falling back to the default' do
          expect(raised.message).to include('502')
        end
      end

      context 'with with_distance parameter' do
        subject(:response) do
          client.time_filter_fast_proto(country: country, origin: {}, destinations: {}, transport: transport,
                                        traveltime: 0, with_distance: true)
        end

        it_behaves_like 'an endpoint method'
      end

      context 'with many_to_one request_type' do
        subject(:response) do
          client.time_filter_fast_proto(country: country, origin: {}, destinations: {}, transport: transport,
                                        traveltime: 0, request_type: TravelTime::ProtoUtils::MANY_TO_ONE)
        end

        it_behaves_like 'an endpoint method'
      end

      context 'with many_to_one and with_distance' do
        subject(:response) do
          client.time_filter_fast_proto(country: country, origin: {}, destinations: {}, transport: transport,
                                        traveltime: 0, with_distance: true,
                                        request_type: TravelTime::ProtoUtils::MANY_TO_ONE)
        end

        it_behaves_like 'an endpoint method'
      end

      [['driving+pt', 'pt'], ['driving+ferry', 'driving+ferry']].each do |transport_name, segment|
        context "with transport #{transport_name}" do
          let(:requested_paths) { [] }

          before do
            paths = requested_paths
            stub_request(:post, /.*/).to_return do |request|
              paths << request.uri.path
              { status: 200 }
            end
            client.time_filter_fast_proto(country: country, origin: {}, destinations: {},
                                          transport: transport_name, traveltime: 0)
          end

          it "posts to the #{segment} url segment" do
            expect(requested_paths).to eq(["/api/v3/#{country}/time-filter/fast/#{segment}"])
          end
        end
      end

      context 'with credentials configured' do
        let(:authorized_stub) do
          stub_request(:post, 'https://proto.api.traveltimeapp.com/api/v3/uk/time-filter/fast/pt')
            .with(headers: { 'Authorization' => "Basic #{Base64.strict_encode64('app-id:api-key')}" })
        end

        before do
          TravelTime.config.application_id = 'app-id'
          TravelTime.config.api_key = 'api-key'
          authorized_stub
          response
        end

        it 'sends credentials over HTTPS to the proto host' do
          expect(authorized_stub).to have_been_requested
        end
      end

      context 'with an uppercase country' do
        before do
          client.time_filter_fast_proto(country: country.upcase, origin: {}, destinations: {},
                                        transport: transport, traveltime: 0)
        end

        it 'posts to the lowercase country segment' do
          expect(stub).to have_been_requested
        end
      end

      context 'with a country that looks like an absolute url' do
        let(:requested_hosts) { [] }

        before do
          hosts = requested_hosts
          stub_request(:post, /.*/).to_return do |request|
            hosts << request.uri.host
            { status: 200 }
          end
          client.time_filter_fast_proto(country: 'https://attacker.example.com', origin: {}, destinations: {},
                                        transport: transport, traveltime: 0)
        end

        it 'keeps the request on the proto host' do
          expect(requested_hosts).to eq(['proto.api.traveltimeapp.com'])
        end
      end
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

    describe '#h3' do
      subject(:response) { client.h3(resolution: 5, properties: %w[min max mean]) }

      let(:url) { "#{described_class::API_BASE_URL}h3" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#h3_fast' do
      subject(:response) { client.h3_fast(resolution: 5, properties: %w[min max mean], arrival_searches: []) }

      let(:url) { "#{described_class::API_BASE_URL}h3/fast" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#geohash' do
      subject(:response) { client.geohash(resolution: 3, properties: %w[min max mean]) }

      let(:url) { "#{described_class::API_BASE_URL}geohash" }
      let(:stub) { stub_request(:post, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#geohash_fast' do
      subject(:response) { client.geohash_fast(resolution: 3, properties: %w[min max mean], arrival_searches: []) }

      let(:url) { "#{described_class::API_BASE_URL}geohash/fast" }
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
