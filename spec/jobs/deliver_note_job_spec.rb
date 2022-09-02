require 'rails_helper'

RSpec.describe DeliverNoteJob, type: :job do
  let!(:subscriber) { create(:subscriber, is_active: true) }
  let!(:note) { create(:message) }

  it 'sends the subscriber the one available note' do
    expect { described_class.perform_now(subscriber.id) }
      .to change { SubscriberEmail.delivered.count }.by(1)

    expect(SubscriberEmail.delivered.last.message).to eq(note)
  end

  it 'skips a subscriber who unsubscribed between dispatch and delivery' do
    subscriber.update!(is_active: false)

    expect { described_class.perform_now(subscriber.id) }.not_to change { SubscriberEmail.count }
  end

  it 'sends nothing when another tick already claimed this interval' do
    described_class.perform_now(subscriber.id)
    create(:message)

    expect { described_class.perform_now(subscriber.id) }
      .not_to change { SubscriberEmail.count }
  end

  it 'sends again once the interval has elapsed' do
    described_class.perform_now(subscriber.id)
    create(:message)
    subscriber.update!(last_delivered_at: 2.minutes.ago)

    expect { described_class.perform_now(subscriber.id) }
      .to change { SubscriberEmail.delivered.count }.by(1)
  end

  it 'discards quietly when the subscriber has been deleted' do
    id = subscriber.id
    subscriber.destroy

    expect { described_class.perform_now(id) }.not_to raise_error
  end

  it 'runs on the deliveries queue so a backlog cannot starve the dispatcher' do
    expect(described_class.new.queue_name).to eq('deliveries')
    expect(DispatchDeliveriesJob.new.queue_name).to eq('default')
  end
end
