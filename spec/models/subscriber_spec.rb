require 'rails_helper'

RSpec.describe Subscriber, type: :model do
  subject { build(:subscriber) }

  let(:subscriber) { described_class.create!(name: 'example name', email: 'example@test.com') }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }

    it { is_expected.to validate_length_of(:name).is_at_most(50) }
    it { is_expected.to validate_length_of(:email).is_at_most(50) }

    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

    it { is_expected.to have_many(:subscriber_emails).dependent(:destroy) }
    it { is_expected.to have_many(:messages).through(:subscriber_emails) }

    it 'rejects a malformed email address' do
      expect(build(:subscriber, email: 'not-an-email')).not_to be_valid
    end

    it 'defaults to active' do
      expect(subscriber.is_active).to be(true)
    end
  end

  describe 'email normalisation' do
    it 'strips and downcases the address before saving' do
      record = described_class.create!(name: 'mixed case', email: '  Mixed.Case@Example.COM ')

      expect(record.email).to eq('mixed.case@example.com')
    end

    it 'prevents the same address subscribing twice under a different case' do
      subscriber
      duplicate = described_class.new(name: 'copy', email: 'EXAMPLE@test.com')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end
  end

  describe '.active' do
    it 'only returns subscribers that are still active' do
      active = create(:subscriber, is_active: true)
      inactive = create(:subscriber, is_active: false)

      expect(described_class.active).to include(active)
      expect(described_class.active).not_to include(inactive)
    end
  end

  describe '.due' do
    it 'includes an active subscriber who has never been sent a note' do
      expect(described_class.due).to include(create(:subscriber, is_active: true))
    end

    it 'excludes an inactive subscriber' do
      expect(described_class.due).not_to include(create(:subscriber, is_active: false))
    end

    it 'excludes a subscriber sent a note inside the delivery interval' do
      recent = create(:subscriber, last_delivered_at: Time.current)

      expect(described_class.due).not_to include(recent)
    end

    it 'includes a subscriber again once the interval has elapsed' do
      lapsed = create(:subscriber, last_delivered_at: 1.hour.ago)

      expect(described_class.due).to include(lapsed)
    end
  end

  describe '#change_status' do
    it 'toggles active flag' do
      expect { subscriber.change_status }
        .to change { subscriber.reload.is_active }.from(true).to(false)
    end

    it 'toggles the flag back on for an inactive subscriber' do
      inactive = create(:subscriber, is_active: false)

      expect { inactive.change_status }
        .to change { inactive.reload.is_active }.from(false).to(true)
    end
  end
end
