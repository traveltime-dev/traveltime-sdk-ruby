# frozen_string_literal: true

RSpec.describe TravelTime::Client do
  let(:client) { described_class.new }
  let(:connection) { client.connection }

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
      let(:success_response) { { body: '' } }
      let(:stub) { stub_request(:get, url) }

      it_behaves_like 'an endpoint method'
    end

    describe '#geocoding' do
      subject(:response) { client.geocoding(**params) }

      let(:url) { "#{described_class::API_BASE_URL}geocoding/search" }
      let(:params) { { query: 'London' } }
      let(:success_response) do
        {
          headers: { 'Content-Type': 'application/json' },
          body: JSON.dump({
                            type: 'FeatureCollection',
                            features: []
                          })
        }
      end
      let(:stub) do
        stub_request(:get, url)
          .with(query: params)
      end

      it_behaves_like 'an endpoint method'
    end
  end
end
