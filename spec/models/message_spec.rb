require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:text) }

    it { is_expected.to validate_length_of(:text).is_at_most(500) }

    it { is_expected.to have_many(:subscriber_emails).dependent(:destroy) }
    it { is_expected.to have_many(:subscribers).through(:subscriber_emails) }

    it { is_expected.to validate_inclusion_of(:review_status).in_array(Message::REVIEW_STATUSES) }

    it 'is approved until screening says otherwise' do
      expect(create(:message).review_status).to eq(Message::APPROVED)
    end
  end

  describe '.deliverable' do
    it 'excludes rejected notes and keeps flagged ones' do
      approved = create(:message)
      flagged = create(:message, :flagged)
      rejected = create(:message, :rejected)

      expect(described_class.deliverable).to contain_exactly(approved, flagged)
      expect(described_class.deliverable).not_to include(rejected)
    end
  end

  describe '.unsent_to' do
    it 'excludes notes the subscriber already has a delivery row for' do
      subscriber = create(:subscriber)
      seen = create(:message)
      unseen = create(:message)
      create(:subscriber_email, subscriber: subscriber, message: seen)

      expect(described_class.unsent_to(subscriber.id)).to contain_exactly(unseen)
    end

    it 'excludes a note whose delivery failed, so it is never retried' do
      subscriber = create(:subscriber)
      failed = create(:message)
      create(:subscriber_email, :failed, subscriber: subscriber, message: failed)

      expect(described_class.unsent_to(subscriber.id)).to be_empty
    end
  end

  describe '#record_review' do
    it 'stores the status, the reviewer and when it ran' do
      note = create(:message)

      note.record_review(Moderation::Verdict.new(status: Message::FLAGGED, notes: 'dismissive', reviewer: 'heuristic'))

      expect(note.review_status).to eq(Message::FLAGGED)
      expect(note.review_notes).to eq('heuristic: dismissive')
      expect(note.reviewed_at).to be_present
    end
  end

  describe 'deletion' do
    it 'removes the delivery records that point at it' do
      subscriber_email = create(:subscriber_email)

      expect { subscriber_email.message.destroy }
        .to change { SubscriberEmail.count }.by(-1)
    end
  end
end
