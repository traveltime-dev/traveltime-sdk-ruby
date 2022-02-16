# frozen_string_literal: true

RSpec.describe TravelTime::Response do
  let(:hash) do
    {
      status: 200,
      headers: {},
      body: {}
    }
  end

  let(:object) do
    Faraday::Response.new(
      status: 200,
      response_headers: {},
      response_body: {}
    )
  end

  describe '.from_object' do
    let(:response) { described_class.from_object(object) }

    it 'sets the status' do
      expect(response.status).to eq(200)
    end

    it 'sets the headers' do
      expect(response.headers).to eq({})
    end

    it 'sets the body' do
      expect(response.body).to eq({})
    end
  end

  describe '.from_hash' do
    let(:response) { described_class.from_hash(hash) }

    it 'sets the status' do
      expect(response.status).to eq(200)
    end

    it 'sets the headers' do
      expect(response.headers).to eq({})
    end

    it 'sets the body' do
      expect(response.body).to eq({})
    end
  end

  describe '#success?' do
    context 'when request was successful' do
      let(:response) { described_class.new(status: 200) }

      it 'returns true' do
        expect(response).to be_success
      end
    end

    context 'when request was not successful' do
      let(:response) { described_class.new(status: 400) }

      it 'returns false' do
        expect(response).not_to be_success
      end
    end
  end
end
