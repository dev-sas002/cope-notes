require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:message) { Message.create(text: 'first message') }

  describe 'validations' do
    it { should validate_presence_of(:text) }

    it { should validate_length_of(:text).is_at_most(500) }

    it { should have_many(:subscriber_emails).dependent(:destroy) }
    it { should have_many(:subscribers).through(:subscriber_emails) }
  end
end