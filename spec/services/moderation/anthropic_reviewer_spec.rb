require 'rails_helper'

# Every example here stubs the HTTP layer. No spec in this suite may make a real
# call to a paid API.
RSpec.describe Moderation::AnthropicReviewer do
  let(:http) { instance_double(Net::HTTP) }

  before do
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
  end

  def stub_response(code_class, body, code = '200')
    response = code_class.new('1.1', code, 'OK')
    allow(response).to receive(:body).and_return(body)
    allow(http).to receive(:request).and_return(response)
    response
  end

  def message_payload(text)
    JSON.generate(content: [{ type: 'text', text: text }])
  end

  describe '.configured?' do
    it 'is false when no API key is set' do
      expect(described_class).not_to be_configured
    end

    it 'is true once a key is present' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ANTHROPIC_API_KEY').and_return('sk-test')

      expect(described_class).to be_configured
    end
  end

  describe '#review' do
    subject(:reviewer) { described_class.new(api_key: 'sk-test') }

    it 'returns the verdict the model gives' do
      stub_response(Net::HTTPOK,
                    message_payload('{"status":"rejected","notes":"tells the reader to stop taking medication"}'))

      verdict = reviewer.review('stop your pills')

      expect(verdict).to be_rejected
      expect(verdict.notes).to eq('tells the reader to stop taking medication')
      expect(verdict.reviewer).to start_with('anthropic/')
    end

    it 'tolerates prose around the JSON object' do
      stub_response(Net::HTTPOK,
                    message_payload("Here you go:\n{\"status\":\"approved\",\"notes\":\"safe\"}\nHope that helps."))

      expect(reviewer.review('you are doing fine').status).to eq(Message::APPROVED)
    end

    it 'sends the note text and the configured model' do
      stub_response(Net::HTTPOK, message_payload('{"status":"approved"}'))
      reviewer.review('a kind note')

      expect(http).to have_received(:request) do |request|
        body = JSON.parse(request.body)
        expect(body['model']).to eq(described_class::DEFAULT_MODEL)
        expect(body['messages'].first['content']).to include('a kind note')
      end
    end

    it 'raises when the API returns an error status' do
      stub_response(Net::HTTPTooManyRequests, '', '429')

      expect { reviewer.review('anything') }
        .to raise_error(described_class::ReviewError, /Anthropic API returned 429/)
    end

    it 'raises when the response contains no JSON object' do
      stub_response(Net::HTTPOK, message_payload('I would rather not say'))

      expect { reviewer.review('anything') }.to raise_error(described_class::ReviewError, /no JSON object/)
    end

    it 'raises when the model invents a status' do
      stub_response(Net::HTTPOK, message_payload('{"status":"maybe"}'))

      expect { reviewer.review('anything') }.to raise_error(described_class::ReviewError, /unknown status/)
    end

    it 'refuses to build without a key' do
      expect { described_class.new(api_key: nil) }.to raise_error(described_class::ReviewError, /ANTHROPIC_API_KEY/)
    end
  end
end
