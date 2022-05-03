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
  let(:error_response) do
    TravelTime::Response.new(
      status: 422,
      body: {
        'http_status' => 422,
        'error_code' => 15,
        'description' => 'We do not have public transport data for the region at the time you have specified.',
        'documentation_link' => 'http://docs.traveltimeplatform.com/reference/error-codes',
        'additional_info' => {
          'search_id' => ['Search#1234']
        }
      }
    )
  end

  context 'when initialized with a response' do
    let(:exception) { described_class.new(response: response) }

    it 'stores the response' do
      expect(exception.response).to eq(response)
    end

    it 'uses the description from response body as message' do
      expect(exception.message).to eq(response.body['description'])
    end

    context 'when body is empty' do
      let(:exception) { described_class.new(response: response_no_body) }

      it 'defaults to the default message' do
        expect(exception.message).to eq(described_class::DEFAULT_MESSAGE)
      end

      it 'returns an empty description' do
        expect(exception.description).to be_nil
      end

      it 'returns an empty error_code' do
        expect(exception.error_code).to be_nil
      end

      it 'returns an empty additional_info' do
        expect(exception.additional_info).to be_nil
      end

      it 'returns an empty documentation_link' do
        expect(exception.documentation_link).to be_nil
      end
    end
  end

  context 'when initialized with an error response' do
    let(:exception) { described_class.new(response: error_response) }

    it 'exposes the description' do
      expect(exception.description).to eq(error_response.body['description'])
    end

    it 'exposes the error_code' do
      expect(exception.error_code).to eq(error_response.body['error_code'])
    end

    it 'exposes the additional_info' do
      expect(exception.additional_info).to eq(error_response.body['additional_info'])
    end

    it 'exposes the documentation_link' do
      expect(exception.documentation_link).to eq(error_response.body['documentation_link'])
    end
  end

  context 'when initialized with a message' do
    let(:exception) { described_class.new(message) }

    it 'uses the message' do
      expect(exception.message).to eq(message)
    end
  end

  context 'when initialized with both a response and a message' do
    let(:exception) { described_class.new(message, response: response) }

    it 'the message takes priority over the description in the response body' do
      expect(exception.message).to eq(message)
    end
  end
end
