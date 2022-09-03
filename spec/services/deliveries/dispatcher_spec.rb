require 'rails_helper'

RSpec.describe Deliveries::Dispatcher do
  let!(:active) { create(:subscriber, is_active: true) }
  let!(:inactive) { create(:subscriber, is_active: false) }

  it 'enqueues one delivery job per due subscriber' do
    expect { described_class.call }.to have_enqueued_job(DeliverNoteJob).with(active.id).once
  end

  it 'does not enqueue anything for inactive subscribers' do
    described_class.call

    expect(enqueued_jobs.map { |job| job[:args].first }).to eq([active.id])
    expect(enqueued_jobs.map { |job| job[:args].first }).not_to include(inactive.id)
  end

  it 'returns how many subscribers it enqueued' do
    create_list(:subscriber, 3, is_active: true)

    expect(described_class.call).to eq(4)
  end

  it 'skips a subscriber who was sent a note within the delivery interval' do
    active.update!(last_delivered_at: Time.current)

    expect(described_class.call).to eq(0)
  end

  it 'includes a subscriber again once the interval has elapsed' do
    active.update!(last_delivered_at: 10.minutes.ago)

    expect(described_class.call).to eq(1)
  end

  it 'walks every subscriber when the batch is smaller than the due set' do
    create_list(:subscriber, 4, is_active: true)

    expect(described_class.new(batch_size: 2).call).to eq(5)
    expect(enqueued_jobs.size).to eq(5)
  end

  it 'scatters jobs across the spread window when one is configured' do
    described_class.new(spread_seconds: 30).call

    expect(enqueued_jobs.size).to eq(1)
    expect(enqueued_jobs.first[:at]).to be_present
  end
end
