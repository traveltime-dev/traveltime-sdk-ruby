# frozen_string_literal: true

RSpec.describe TravelTime::Middleware::ProtoMiddleware do
  let(:faraday_env) do
    Faraday::Env.new.tap do |env|
      env.request_headers = Faraday::Utils::Headers.new
    end
  end
  let(:middleware) { described_class.new }

  it 'adds basic auth header' do
    middleware.on_request(faraday_env)
    value = faraday_env.request_headers['Authorization']
    expect(value).to be_truthy
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
end
