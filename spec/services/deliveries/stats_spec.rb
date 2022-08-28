require 'rails_helper'

RSpec.describe Deliveries::Stats do
  it 'reports the configuration and the pipeline state' do
    subscriber = create(:subscriber, is_active: true)
    create(:subscriber, is_active: false)
    note = create(:message)
    create(:message, :rejected)
    create(:subscriber_email, subscriber: subscriber, message: note)

    stats = described_class.call

    expect(stats[:channel]).to eq(:email)
    expect(stats[:selection_strategy]).to eq(:random_unsent)
    expect(stats[:interval_minutes]).to eq(1)
    expect(stats[:subscribers]).to include(total: 2, active: 1)
    expect(stats[:notes]).to include(total: 2, deliverable: 1)
    expect(stats[:deliveries][:by_status]).to eq(SubscriberEmail::DELIVERED => 1)
  end

  it 'counts a subscriber who has received every deliverable note as exhausted' do
    subscriber = create(:subscriber, is_active: true)
    create(:subscriber_email, subscriber: subscriber, message: create(:message))

    expect(described_class.call[:subscribers][:exhausted]).to eq(1)
  end

  it 'reports zero deliveries and no exhausted subscribers on an empty install' do
    stats = described_class.call

    expect(stats[:deliveries][:total]).to eq(0)
    expect(stats[:subscribers][:exhausted]).to eq(0)
  end
end
