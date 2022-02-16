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
    let(:instance) { described_class.from_object(object) }

    it 'sets the status' do
      expect(instance.status).to eq(200)
    end

    it 'sets the headers' do
      expect(instance.headers).to eq({})
    end

    it 'sets the body' do
      expect(instance.body).to eq({})
    end
  end

  describe '.from_hash' do
    let(:instance) { described_class.from_hash(hash) }

    it 'sets the status' do
      expect(instance.status).to eq(200)
    end

    it 'sets the headers' do
      expect(instance.headers).to eq({})
    end

    it 'sets the body' do
      expect(instance.body).to eq({})
    end
  end

  describe '#success?' do
    context 'when request was successful' do
      let(:instance) { described_class.new(status: 200) }

      it 'returns true' do
        expect(instance.success?).to be_truthy
      end
    end

    context 'when request was not successful' do
      let(:instance) { described_class.new(status: 400) }

      it 'returns false' do
        expect(instance.success?).to be_falsey
      end
    end
  end
end
