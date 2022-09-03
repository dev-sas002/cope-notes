require 'rails_helper'

RSpec.describe Deliveries::SendNextNote do
  subject(:service) { described_class.new(subscriber) }

  let!(:subscriber) { create(:subscriber, is_active: true) }
  let!(:note) { create(:message, text: 'There is hope.') }

  before { ActionMailer::Base.deliveries.clear }

  describe 'a successful delivery' do
    it 'records a confirmed delivery and sends the mail' do
      expect { service.call }.to change { SubscriberEmail.count }.by(1)

      delivery = SubscriberEmail.last
      expect(delivery.subscriber).to eq(subscriber)
      expect(delivery.message).to eq(note)
      expect(delivery.status).to eq(SubscriberEmail::DELIVERED)
      expect(delivery.delivered_at).to be_present
      expect(delivery.channel).to eq('email')
      expect(ActionMailer::Base.deliveries.map(&:to).flatten).to eq([subscriber.email])
    end

    it 'returns a delivered result and stamps the subscriber' do
      result = service.call

      expect(result).to be_delivered
      expect(result.note).to eq(note)
      expect(subscriber.reload.last_delivered_at).to be_present
    end

    it 'never sends the same note to the same subscriber twice' do
      second_note = create(:message, text: 'second')

      2.times { described_class.new(subscriber).call }

      expect(subscriber.reload.messages).to contain_exactly(note, second_note)
      expect(ActionMailer::Base.deliveries.size).to eq(2)
    end
  end

  describe 'when there is nothing to send' do
    it 'skips a subscriber who has already had every note' do
      create(:subscriber_email, subscriber: subscriber, message: note)

      expect { expect(service.call).to be_skipped }.not_to change { SubscriberEmail.count }
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'skips when the only note has been rejected by screening' do
      note.update!(review_status: Message::REJECTED)

      expect { expect(service.call).to be_skipped }.not_to change { SubscriberEmail.count }
    end

    it 'skips when another worker already claimed the only note' do
      selector = instance_double(Deliveries::Selectors::RandomUnsent, call: note)
      create(:subscriber_email, :claimed, subscriber: subscriber, message: note)

      result = described_class.new(subscriber, selector: selector).call

      expect(result).to be_skipped
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  describe 'when the channel fails' do
    let(:channel) { instance_double(Deliveries::Channels::Email, name: 'email') }

    before { allow(Rails.logger).to receive(:error) }

    it 'releases the claim for a transient failure so the note is retried' do
      allow(channel).to receive(:deliver).and_raise(Deliveries::TransientError, 'connection refused')

      result = described_class.new(subscriber, channel: channel).call

      expect(result).to be_released
      expect(SubscriberEmail.where(subscriber: subscriber)).to be_empty
      expect(Rails.logger).to have_received(:error).with(/released for retry/)
    end

    it 'offers the same note again on the next attempt after a transient failure' do
      allow(channel).to receive(:deliver).and_raise(Deliveries::TransientError, 'connection refused')
      described_class.new(subscriber, channel: channel).call

      expect(described_class.new(subscriber).call).to be_delivered
      expect(SubscriberEmail.last.message).to eq(note)
    end

    it 'keeps the claim as failed for an ambiguous failure' do
      allow(channel).to receive(:deliver).and_raise(StandardError, 'mailbox unavailable')

      result = described_class.new(subscriber, channel: channel).call

      expect(result).to be_failed
      delivery = SubscriberEmail.find_by(subscriber: subscriber)
      expect(delivery.status).to eq(SubscriberEmail::FAILED)
      expect(delivery.delivered_at).to be_nil
      expect(delivery.failure_reason).to include('mailbox unavailable')
    end

    it 'does not retry an ambiguously failed note, and sends a different one instead' do
      other_note = create(:message, text: 'another')
      allow(channel).to receive(:deliver).and_raise(StandardError, 'mailbox unavailable')
      failed = described_class.new(subscriber, channel: channel).call.note

      result = described_class.new(subscriber).call

      expect(result).to be_delivered
      expect(result.note).to eq([note, other_note].find { |candidate| candidate != failed })
    end
  end
end
