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

    # Active subscribers for whom no deliverable note is left, so they will not
    # be sent anything again until new notes are written. "Left" means exactly
    # what the selectors mean: a deliverable note with no delivery row of any
    # status for this subscriber. Counting delivered rows instead would miss
    # subscribers whose remaining notes all failed, and would count a note that
    # was delivered and later rejected as if it were still in circulation.
    def exhausted_subscribers
      return 0 unless Message.deliverable.exists?

      Subscriber.active.where(<<~SQL.squish).count
        NOT EXISTS (
          SELECT 1 FROM messages
          WHERE messages.review_status <> '#{Message::REJECTED}'
            AND NOT EXISTS (
              SELECT 1 FROM subscriber_emails se
              WHERE se.message_id = messages.id AND se.subscriber_id = subscribers.id
            )
        )
      SQL
    end
  end
end
