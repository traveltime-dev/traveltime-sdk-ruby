# frozen_string_literal: true

RSpec.shared_examples 'an endpoint method' do
  context 'when request is successful' do
    before { stub }

    it 'returns a response object' do
      expect(response).to be_a(TravelTime::Response)
    end
  end

  context 'when request is not successful' do
    before { stub.to_return(status: 401) }

    it 'returns a response object' do
      expect(response).to be_a(TravelTime::Response)
    end
  end

  context 'when request times out' do
    before { stub.to_timeout }

    it 'raises an error' do
      expect { response }.to raise_error(TravelTime::Error)
    end
  end

  context 'when raising an unexpected error' do
    let(:unexpected_error) { Class.new(StandardError) }

    before { stub.to_raise(unexpected_error) }

    it 'raises an error' do
      expect { response }.to raise_error(TravelTime::Error)
    end
  end
end
