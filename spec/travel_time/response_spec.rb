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

  describe '.from_object_proto' do
    let(:error_headers) do
      { 'X-ERROR-CODE' => '8', 'X-ERROR-MESSAGE' => 'Unsupported mode', 'X-ERROR-DETAILS' => 'try pt' }
    end

    context 'when the request failed' do
      let(:response) do
        described_class.from_object_proto(
          Faraday::Response.new(status: 400, response_headers: error_headers, response_body: '')
        )
      end

      it 'surfaces the error headers under the keys TravelTime::Error reads' do
        expect(response.body).to eq('error_code' => '8', 'description' => 'Unsupported mode',
                                    'additional_info' => 'try pt')
      end

      it 'still exposes the raw headers' do
        expect(response.headers).to eq(error_headers)
      end
    end

    context 'when the error headers are absent' do
      let(:response) do
        described_class.from_object_proto(
          Faraday::Response.new(status: 500, response_headers: {}, response_body: '')
        )
      end

      it 'yields nil for each field rather than raising' do
        expect(response.body).to eq('error_code' => nil, 'description' => nil, 'additional_info' => nil)
      end
    end

    context 'when the request succeeded' do
      let(:response) do
        described_class.from_object_proto(
          Faraday::Response.new(status: 200, response_headers: {}, response_body: '')
        )
      end

      it 'decodes the proto body instead of building an error' do
        expect(response.body).to eq(TravelTime::ProtoUtils.decode_proto_response(''))
      end
    end
  end

  describe '.from_proto_error' do
    let(:response) do
      described_class.from_proto_error(
        status: 400,
        headers: { 'X-ERROR-CODE' => '8', 'X-ERROR-MESSAGE' => 'Unsupported mode' },
        body: ''
      )
    end

    it 'builds the error body from the headers, ignoring the raw body' do
      expect(response.body).to eq('error_code' => '8', 'description' => 'Unsupported mode',
                                  'additional_info' => nil)
    end

    it 'sets the status' do
      expect(response.status).to eq(400)
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
