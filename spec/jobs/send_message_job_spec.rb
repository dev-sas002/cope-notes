require 'rails_helper'

RSpec.describe SendMessageJob, type: :job do
  describe '#perform' do
    let!(:message_one) { create(:message, text: 'first') }
    let!(:message_two) { create(:message, text: 'second') }
    let!(:active_subscriber) { create(:subscriber, is_active: true) }
    let!(:inactive_subscriber) { create(:subscriber, is_active: false) }

    before do
      allow(MessageMailer).to receive_message_chain(:with, :new_message_email, :deliver_now)
      allow_any_instance_of(Array).to receive(:sample).and_return(message_one.id)
    end

    it 'creates delivery only for active subscriber with unsent messages' do
      expect do
        described_class.perform_now
      end.to change { SubscriberEmail.count }.by(1)

      expect(SubscriberEmail.last.subscriber).to eq(active_subscriber)
      expect(MessageMailer).to have_received(:with).with(subscriber: active_subscriber, message: message_one)
    end

    it 'does not create a duplicate subscriber-email pair' do
      create(:subscriber_email, subscriber: active_subscriber, message: message_one)
      allow_any_instance_of(Array).to receive(:sample).and_return(message_two.id)

      expect do
        described_class.perform_now
      end.to change { SubscriberEmail.count }.by(1)

      expect(active_subscriber.messages).to include(message_one, message_two)
    end
  end
end
