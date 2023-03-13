# frozen_string_literal: true

RSpec.describe TravelTime::Middleware::Authentication do
  let(:faraday_env) do
    Faraday::Env.new.tap do |env|
      env.request_headers = Faraday::Utils::Headers.new
    end
  end
  let(:middleware) { described_class.new }

  it 'automatically fetches the application_id from the configuration and set it for the request' do
    middleware.on_request(faraday_env)
    value = faraday_env.request_headers[described_class::APP_ID_HEADER]
    expected = TravelTime.config.application_id
    expect(value).to eq(expected)
  end

  it 'automatically fetches the api_key from the configuration and set it for the request' do
    middleware.on_request(faraday_env)
    value = faraday_env.request_headers[described_class::API_KEY_HEADER]
    expected = TravelTime.config.api_key
    expect(value).to eq(expected)
  end

  it 'automatically adds User-Agent header' do
    middleware.on_request(faraday_env)
    value = faraday_env.request_headers[described_class::USER_AGENT]
    expected = "Travel Time Ruby SDK #{TravelTime::VERSION}"
    expect(value).to eq(expected)
  end
end
