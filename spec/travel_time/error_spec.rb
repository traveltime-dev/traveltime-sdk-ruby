# frozen_string_literal: true

RSpec.describe TravelTime::Error do
  let(:message) { 'error_message' }
  let(:response) do
    TravelTime::Response.new(
      body: { 'description' => 'error_description' }
    )
  end
  let(:response_no_body) do
    TravelTime::Response.new
  end

  context 'when initialized with a response' do
    let(:exception) { described_class.new(response: response) }

    it 'stores the response' do
      expect(exception.response).to eq(response)
    end

    it 'uses the description from response body as message' do
      expect(exception.message).to eq(response.body['description'])
    end

    context 'when description is missing from body' do
      let(:exception) { described_class.new(response: response_no_body) }

      it 'defaults to the default message' do
        expect(exception.message).to eq(described_class::DEFAULT_MESSAGE)
      end
    end
  end

  context 'when initialized with a message' do
    let(:exception) { described_class.new(message: message) }

    it 'uses the message' do
      expect(exception.message).to eq(message)
    end
  end

  context 'when initialized with both a response and a message' do
    let(:exception) { described_class.new(response: response, message: message) }

    it 'the message takes priority over the description in the response body' do
      expect(exception.message).to eq(message)
    end
  end
end
