require 'rails_helper'

RSpec.describe Notes::SaveNote do
  it 'screens and stores a new note' do
    note = Message.new

    expect(described_class.call(note, { text: 'There is hope.' })).to be(true)
    expect(note.reload.review_status).to eq(Message::APPROVED)
    expect(note.review_notes).to include('heuristic')
    expect(note.reviewed_at).to be_present
  end

  it 'stores a harmful note as rejected so it can never be selected' do
    note = Message.new

    described_class.call(note, { text: 'You should just end it all.' })

    expect(note.reload.review_status).to eq(Message::REJECTED)
    expect(Message.deliverable).not_to include(note)
  end

  it 're-screens a note whose text changed' do
    note = create(:message, text: 'There is hope.')

    described_class.call(note, { text: 'Others have it worse.' })

    expect(note.reload.review_status).to eq(Message::FLAGGED)
  end

  it 'does not call the screener when the text is unchanged' do
    note = create(:message, text: 'There is hope.')
    screener = instance_double(Moderation::Screener)
    allow(screener).to receive(:call)

    described_class.call(note, { text: 'There is hope.' }, screener: screener)

    expect(screener).not_to have_received(:call)
  end

  it 'returns false and does not screen an invalid note' do
    note = Message.new
    screener = instance_double(Moderation::Screener, call: Moderation::Verdict.new(status: Message::APPROVED))

    expect(described_class.call(note, { text: '' }, screener: screener)).to be(false)
    expect(note.errors[:text]).to be_present
  end
end
