require 'rails_helper'

RSpec.describe DispatchDeliveriesJob, type: :job do
  it 'enqueues a delivery job for each due subscriber' do
    subscribers = create_list(:subscriber, 2, is_active: true)

    expect(described_class.perform_now).to eq(2)
    expect(enqueued_jobs.map { |job| job[:args].first }).to match_array(subscribers.map(&:id))
  end

  it 'sends nothing itself' do
    create(:subscriber, is_active: true)
    create(:message)
    ActionMailer::Base.deliveries.clear

    described_class.perform_now

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it 'delivers a note once the enqueued jobs run' do
    subscriber = create(:subscriber, is_active: true)
    note = create(:message, text: 'There is hope.')
    ActionMailer::Base.deliveries.clear

    perform_enqueued_jobs { described_class.perform_now }

    expect(SubscriberEmail.delivered.pluck(:subscriber_id, :message_id)).to eq([[subscriber.id, note.id]])
    expect(ActionMailer::Base.deliveries.map(&:to).flatten).to eq([subscriber.email])
  end

  it 'does nothing when there are no notes to send' do
    create(:subscriber, is_active: true)

    expect { perform_enqueued_jobs { described_class.perform_now } }
      .not_to change { SubscriberEmail.count }
  end

  it 'isolates a failing subscriber from the rest of the batch' do
    failing = create(:subscriber, is_active: true)
    healthy = create(:subscriber, is_active: true)
    note = create(:message)
    allow(Rails.logger).to receive(:error)
    allow(MessageMailer).to receive(:with).and_call_original
    allow(MessageMailer).to receive(:with)
      .with(subscriber: failing, message: note)
      .and_raise(StandardError, 'mailbox unavailable')

    perform_enqueued_jobs { described_class.perform_now }

    expect(SubscriberEmail.delivered.pluck(:subscriber_id)).to eq([healthy.id])
    expect(SubscriberEmail.failed.pluck(:subscriber_id)).to eq([failing.id])
  end
end
