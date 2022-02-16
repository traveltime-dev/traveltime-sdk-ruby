# frozen_string_literal: true

RSpec.shared_examples 'an endpoint method' do
  context 'when request is successful' do
    before { stub_request(:get, url) }

    it 'returns a response object' do
      expect(response).to be_a(TravelTime::Response)
    end
  end

  context 'when request is not successful' do
    before do
      stub_request(:get, url).to_return(status: 401)
    end

    it 'returns a response object' do
      expect(response).to be_a(TravelTime::Response)
    end
  end

  context 'when request times out' do
    before do
      stub_request(:get, url).to_timeout
    end

    it 'raises an error' do
      expect { response }.to raise_error(TravelTime::Error)
    end
  end

  context 'when raising an unexpected error' do
    let(:unexpected_error) { Class.new(StandardError) }

    before do
      stub_request(:get, url).to_raise(unexpected_error)
    end

    it 'raises an error' do
      expect { response }.to raise_error(TravelTime::Error)
    end
  end
end
