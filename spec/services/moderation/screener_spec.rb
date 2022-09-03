require 'rails_helper'

RSpec.describe Moderation::Screener do
  it 'returns the reviewer verdict when the reviewer succeeds' do
    verdict = Moderation::Verdict.new(status: Message::FLAGGED, notes: 'dismissive')
    reviewer = instance_double(Moderation::AnthropicReviewer, review: verdict)

    expect(described_class.new(reviewer: reviewer).call('anything')).to eq(verdict)
  end

  it 'falls back to the local reviewer when the AI reviewer fails' do
    reviewer = instance_double(Moderation::AnthropicReviewer)
    allow(reviewer).to receive(:review).and_raise(Moderation::AnthropicReviewer::ReviewError, 'rate limited')
    allow(Rails.logger).to receive(:warn)

    verdict = described_class.new(reviewer: reviewer).call('you should just end it all')

    expect(verdict).to be_rejected
    expect(verdict.reviewer).to eq('heuristic')
    expect(Rails.logger).to have_received(:warn).with(/rate limited/)
  end

  it 'approves rather than blocking when every reviewer fails' do
    reviewer = instance_double(Moderation::AnthropicReviewer)
    fallback = instance_double(Moderation::HeuristicReviewer)
    allow(reviewer).to receive(:review).and_raise(StandardError, 'boom')
    allow(fallback).to receive(:review).and_raise(StandardError, 'also boom')
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)

    verdict = described_class.new(reviewer: reviewer, fallback: fallback).call('anything')

    expect(verdict.status).to eq(Message::APPROVED)
    expect(verdict.reviewer).to eq('none')
  end

  it 'uses the offline reviewer by default when no API key is configured' do
    expect(Moderation.default_reviewer).to be_a(Moderation::HeuristicReviewer)
  end
end
