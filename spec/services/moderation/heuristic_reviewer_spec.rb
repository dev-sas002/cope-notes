require 'rails_helper'

RSpec.describe Moderation::HeuristicReviewer do
  subject(:reviewer) { described_class.new }

  it 'approves an ordinary supportive note' do
    verdict = reviewer.review('There is hope, even when your brain tells you there is not.')

    expect(verdict.status).to eq(Message::APPROVED)
    expect(verdict.reviewer).to eq('heuristic')
  end

  it 'rejects text that encourages self-harm' do
    verdict = reviewer.review('Nothing will get better, you should just end it all.')

    expect(verdict).to be_rejected
    expect(verdict.notes).to eq('encourages self-harm')
  end

  it 'rejects medication advice' do
    verdict = reviewer.review('If you feel low, stop taking your meds for a week.')

    expect(verdict).to be_rejected
    expect(verdict.notes).to eq('gives medication advice')
  end

  it 'flags a dismissive note without blocking it' do
    verdict = reviewer.review('Others have it worse, you know.')

    expect(verdict.status).to eq(Message::FLAGGED)
    expect(verdict).not_to be_rejected
  end

  it 'flags a note that mentions self-harm in passing' do
    expect(reviewer.review('Talking about suicide is hard but you are not alone.').status)
      .to eq(Message::FLAGGED)
  end
end
