require 'rails_helper'
require 'webmock/rspec'

RSpec.describe ContentSafety::OpenaiClient do
  let(:api_key) { 'test-key' }
  let(:client) { described_class.new }
  let(:text) { 'Test content' }

  before do
    ENV['OPENAI_API_KEY'] = api_key
  end

  after do
    ENV.delete('OPENAI_API_KEY')
  end

  describe '#initialize' do
    it 'raises error if API key is missing' do
      ENV.delete('OPENAI_API_KEY')
      expect { described_class.new }.to raise_error(ContentSafety::OpenaiClient::MissingApiKeyError)
    end

    it 'raises error if API key is empty' do
      ENV['OPENAI_API_KEY'] = ''
      expect { described_class.new }.to raise_error(ContentSafety::OpenaiClient::MissingApiKeyError)
    end
  end

  describe '#screen' do
    context 'when API request succeeds' do
      before do
        stub_request(:post, ContentSafety::OpenaiClient::API_URL)
          .with(
            headers: {
              'Authorization' => "Bearer #{api_key}",
              'Content-Type' => 'application/json'
            },
            body: hash_including(model: ContentSafety::OpenaiClient::MODEL, input: text)
          )
          .to_return(
            status: 200,
            body: {
              results: [
                {
                  flagged: true,
                  categories: { 'violence' => true },
                  category_scores: { 'violence' => 0.9 }
                }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns parsed result' do
        result = client.screen(text: text)
        expect(result[:flagged]).to be true
        expect(result[:categories]).to eq({ 'violence' => true })
        expect(result[:category_scores]).to eq({ 'violence' => 0.9 })
      end
    end

    context 'when API returns error' do
      before do
        stub_request(:post, ContentSafety::OpenaiClient::API_URL)
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises Error' do
        expect { client.screen(text: text) }.to raise_error(ContentSafety::OpenaiClient::Error, /API returned 500/)
      end
    end

    context 'when API returns unexpected format' do
      before do
        stub_request(:post, ContentSafety::OpenaiClient::API_URL)
          .to_return(status: 200, body: { results: [] }.to_json)
      end

      it 'raises Error' do
        expect { client.screen(text: text) }.to raise_error(ContentSafety::OpenaiClient::Error, /Unexpected API response format/)
      end
    end

    context 'when network error occurs' do
      before do
        stub_request(:post, ContentSafety::OpenaiClient::API_URL).to_timeout
      end

      it 'raises Error' do
        expect { client.screen(text: text) }.to raise_error(ContentSafety::OpenaiClient::Error, /Failed to screen content/)
      end
    end

    context 'in production environment' do
      before do
        allow(Rails.env).to receive(:development?).and_return(false)
        allow(Rails.env).to receive(:test?).and_return(false)

        stub_request(:post, ContentSafety::OpenaiClient::API_URL)
          .to_return(status: 200, body: { results: [ { flagged: false } ] }.to_json)
      end

      it 'does not disable SSL verification' do
        expect_any_instance_of(Net::HTTP).not_to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
        client.screen(text: text)
      end
    end
  end
end
