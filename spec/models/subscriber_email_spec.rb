require 'rails_helper'

RSpec.describe SubscriberEmail, type: :model do
  describe 'associations and validations' do
    it { is_expected.to belong_to(:subscriber) }
    it { is_expected.to belong_to(:message) }
    it { is_expected.to validate_presence_of(:subscriber) }
    it { is_expected.to validate_presence_of(:message) }
    it { is_expected.to validate_uniqueness_of(:subscriber_id).scoped_to(:message_id) }
  end
end
