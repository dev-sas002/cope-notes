require 'rails_helper'

RSpec.describe Deliveries::Selectors do
  let(:subscriber) { create(:subscriber) }

  it 'resolves the registered strategies' do
    expect(described_class.fetch(:random_unsent)).to be_a(Deliveries::Selectors::RandomUnsent)
    expect(described_class.fetch(:least_delivered)).to be_a(Deliveries::Selectors::LeastDelivered)
  end

  it 'raises a helpful error for an unregistered strategy' do
    expect { described_class.fetch(:astrology) }
      .to raise_error(described_class::UnknownStrategy, /astrology/)
  end

  describe Deliveries::Selectors::RandomUnsent do
    it 'only ever returns a note the subscriber has not received' do
      seen = create(:message, text: 'seen')
      unseen = create(:message, text: 'unseen')
      create(:subscriber_email, subscriber: subscriber, message: seen)

      expect(Array.new(5) { described_class.new.call(subscriber) }).to all(eq(unseen))
    end

    it 'returns nil once every note has been received' do
      note = create(:message)
      create(:subscriber_email, subscriber: subscriber, message: note)

      expect(described_class.new.call(subscriber)).to be_nil
    end

    it 'never returns a rejected note' do
      create(:message, :rejected)

      expect(described_class.new.call(subscriber)).to be_nil
    end

    it 'still returns a flagged note' do
      flagged = create(:message, :flagged)

      expect(described_class.new.call(subscriber)).to eq(flagged)
    end
  end

  describe Deliveries::Selectors::LeastDelivered do
    it 'prefers the note the fewest subscribers have seen' do
      popular = create(:message, text: 'popular')
      fresh = create(:message, text: 'fresh')
      create_list(:subscriber, 3).each { |other| create(:subscriber_email, subscriber: other, message: popular) }

      expect(described_class.new.call(subscriber)).to eq(fresh)
    end

    it 'keeps the counter cache in step with the delivery rows' do
      note = create(:message)

      expect { create(:subscriber_email, subscriber: subscriber, message: note) }
        .to change { note.reload.deliveries_count }.from(0).to(1)
    end
  end
end
