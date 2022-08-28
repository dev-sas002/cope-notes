require 'rails_helper'

RSpec.describe SubscriberEmail, type: :model do
  subject { build(:subscriber_email) }

  describe 'associations and validations' do
    it { is_expected.to belong_to(:subscriber) }
    it { is_expected.to belong_to(:message) }
    it { is_expected.to validate_uniqueness_of(:subscriber_id).scoped_to(:message_id) }
    it { is_expected.to validate_inclusion_of(:status).in_array(SubscriberEmail::STATUSES) }
  end

  describe 'the required associations' do
    it 'refuses a delivery row with no subscriber' do
      record = build(:subscriber_email, subscriber: nil)

      expect(record).not_to be_valid
      expect(record.errors[:subscriber]).to be_present
    end

    it 'refuses a delivery row with no note' do
      record = build(:subscriber_email, message: nil)

      expect(record).not_to be_valid
      expect(record.errors[:message]).to be_present
    end
  end

  describe 'status scopes' do
    it 'separates confirmed, unconfirmed and failed deliveries' do
      delivered = create(:subscriber_email)
      claimed = create(:subscriber_email, :claimed)
      failed = create(:subscriber_email, :failed)

      expect(described_class.delivered).to contain_exactly(delivered)
      expect(described_class.unconfirmed).to contain_exactly(claimed)
      expect(described_class.failed).to contain_exactly(failed)
    end
  end

  describe 'the counter cache on messages' do
    it 'tracks how many subscribers have been sent each note' do
      note = create(:message)

      expect { create(:subscriber_email, message: note) }
        .to change { note.reload.deliveries_count }.from(0).to(1)
    end

    it 'decrements when a claim is released' do
      delivery = create(:subscriber_email)

      expect { delivery.destroy }
        .to change { delivery.message.reload.deliveries_count }.from(1).to(0)
    end
  end

  describe 'uniqueness of the subscriber/message pair' do
    it 'allows the same message to go to different subscribers' do
      first = create(:subscriber_email)
      second = build(:subscriber_email, message: first.message)

      expect(second).to be_valid
    end

    it 'refuses to record the same message twice for one subscriber' do
      first = create(:subscriber_email)
      duplicate = build(:subscriber_email, subscriber: first.subscriber, message: first.message)

      expect(duplicate).not_to be_valid
    end
  end
end
