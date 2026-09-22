# frozen_string_literal: true

RSpec.describe TravelTime::Middleware::ProtoMiddleware do
  let(:url) { 'https://proto.api.traveltimeapp.com/api/v3/uk/time-filter/fast/pt' }
  let(:faraday_env) do
    Faraday::Env.new.tap do |env|
      env.request_headers = Faraday::Utils::Headers.new
      env.url = URI(url)
    end
  end
  let(:middleware) { described_class.new }
  let(:application_id) { 'a' * 40 }
  let(:api_key) { 'b' * 40 }

  before do
    TravelTime.config.application_id = application_id
    TravelTime.config.api_key = api_key
  end

  it 'adds a single-line basic auth header' do
    middleware.on_request(faraday_env)
    value = faraday_env.request_headers['Authorization']
    expected = "Basic #{Base64.strict_encode64("#{application_id}:#{api_key}")}"
    expect(value).to eq(expected)
  end

  it 'automatically adds Accept type header' do
    middleware.on_request(faraday_env)
    value = faraday_env.request_headers['Accept']
    expected = 'application/octet-stream'
    expect(value).to eq(expected)
  end

  it 'automatically adds Content-Type type header' do
    middleware.on_request(faraday_env)
    value = faraday_env.request_headers['Content-Type']
    expected = 'application/octet-stream'
    expect(value).to eq(expected)
  end

  it 'automatically adds User-Agent type header' do
    middleware.on_request(faraday_env)
    value = faraday_env.request_headers['User-Agent']
    expected = "Travel Time Ruby SDK #{TravelTime::VERSION}"
    expect(value).to eq(expected)
  end

  context 'when the request is not over HTTPS' do
    let(:url) { 'http://proto.api.traveltimeapp.com/api/v3/uk/time-filter/fast/pt' }

    it 'refuses to send the request' do
      expect { middleware.on_request(faraday_env) }.to raise_error(TravelTime::Error,
                                                                   'Refusing to send credentials over http')
    end
  end
end
