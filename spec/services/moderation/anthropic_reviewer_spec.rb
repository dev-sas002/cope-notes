require 'rails_helper'

# Every example here injects a fake client. No spec in this suite may make a
# real call to a paid API.
RSpec.describe Moderation::AnthropicReviewer do
  let(:messages) { double('beta.messages') } # rubocop:disable RSpec/VerifiedDoubles -- SDK resource proxies are built dynamically
  let(:client) { double('Anthropic::Client', beta: double('beta', messages: messages)) } # rubocop:disable RSpec/VerifiedDoubles

  def stub_reply(text, stop_reason: :end_turn)
    block = Struct.new(:type, :text).new(:text, text)
    response = Struct.new(:content, :stop_reason).new([block], stop_reason)
    allow(messages).to receive(:create).and_return(response)
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
    subject(:reviewer) { described_class.new(client: client) }

    it 'returns the verdict the model gives' do
      stub_reply('{"status":"rejected","notes":"tells the reader to stop taking medication"}')

      verdict = reviewer.review('stop your pills')

      expect(verdict).to be_rejected
      expect(verdict.notes).to eq('tells the reader to stop taking medication')
      expect(verdict.reviewer).to eq("anthropic/#{described_class::DEFAULT_MODEL}")
    end

    it 'sends the note text, the model, a JSON schema and the fallback opt-in' do
      stub_reply('{"status":"approved","notes":"kind"}')
      reviewer.review('a kind note')

      expect(messages).to have_received(:create) do |params|
        expect(params[:model]).to eq(described_class::DEFAULT_MODEL)
        expect(params[:messages].first[:content]).to include('a kind note')
        expect(params[:output_config]).to include(effort: :low)
        expect(params[:output_config][:format_][:schema][:properties][:status][:enum]).to eq(Message::REVIEW_STATUSES)
        expect(params).to include(fallbacks: :default, betas: [described_class::FALLBACK_BETA])
      end
    end

    it 'raises when every model declines, so the screener falls back' do
      stub_reply('', stop_reason: :refusal)

      expect { reviewer.review('anything') }.to raise_error(described_class::ReviewError, /declined/)
    end

    it 'raises when the response is not JSON' do
      stub_reply('I would rather not say')

      expect { reviewer.review('anything') }.to raise_error(described_class::ReviewError, /could not parse/)
    end

    it 'raises when the model invents a status' do
      stub_reply('{"status":"maybe","notes":""}')

      expect { reviewer.review('anything') }.to raise_error(described_class::ReviewError, /unknown status/)
    end

    it 'lets API errors through for the screener to handle' do
      allow(messages).to receive(:create).and_raise(Anthropic::Errors::APIConnectionError.new(url: nil))

      expect { reviewer.review('anything') }.to raise_error(Anthropic::Errors::APIConnectionError)
    end

    it 'refuses to build without a key or a client' do
      expect { described_class.new(api_key: nil) }.to raise_error(described_class::ReviewError, /ANTHROPIC_API_KEY/)
    end
  end
end
