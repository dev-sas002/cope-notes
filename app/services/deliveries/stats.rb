# frozen_string_literal: true

module Deliveries
  # Operational snapshot of the delivery pipeline, used by
  # GET /api/v1/deliveries/stats.
  #
  # Every figure is an aggregate computed in the database - nothing here loads a
  # collection into Ruby, so the endpoint costs the same with ten deliveries or
  # ten million.
  class Stats
    def self.call(now: Time.current)
      new(now: now).call
    end

    def initialize(now: Time.current)
      @now = now
    end

    def call
      {
        generated_at: now,
        channel: Deliveries.channel_name,
        selection_strategy: Deliveries.selection_strategy,
        interval_minutes: (Deliveries.interval / 60).to_i,
        subscribers: subscriber_counts,
        notes: note_counts,
        deliveries: delivery_counts
      }
    end

    private

    attr_reader :now

    def subscriber_counts
      {
        total: Subscriber.count,
        active: Subscriber.active.count,
        due_now: Subscriber.due(now).count,
        exhausted: exhausted_subscribers
      }
    end

    def note_counts
      {
        total: Message.count,
        deliverable: Message.deliverable.count,
        by_review_status: Message.group(:review_status).count
      }
    end

    def delivery_counts
      {
        total: SubscriberEmail.count,
        by_status: SubscriberEmail.group(:status).count,
        last_24h: SubscriberEmail.where(delivered_at: (now - 24.hours)..now).count
      }
    end

    # Active subscribers who have already received every deliverable note, and
    # so will never be sent anything again until new notes are written.
    def exhausted_subscribers
      deliverable = Message.deliverable.count
      return 0 if deliverable.zero?

      Subscriber.active
                .joins(:subscriber_emails)
                .where(subscriber_emails: { status: SubscriberEmail::DELIVERED })
                .group('subscribers.id')
                .having('COUNT(subscriber_emails.id) >= ?', deliverable)
                .count
                .size
    end
  end
end
