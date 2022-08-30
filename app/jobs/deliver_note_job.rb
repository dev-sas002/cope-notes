# frozen_string_literal: true

# Sends one subscriber one note. One job per subscriber is what gives the
# pipeline its failure isolation: a provider timeout costs one job a retry
# instead of stalling everybody queued behind it.
class DeliverNoteJob < ApplicationJob
  queue_as :deliveries

  # A subscriber deleted between dispatch and delivery is expected, not an error.
  discard_on ActiveRecord::RecordNotFound

  def perform(subscriber_id)
    subscriber = Subscriber.find(subscriber_id)
    # The dispatcher decides who *looks* due; this is where that decision is
    # committed. Dispatch and delivery can be minutes apart under load, and two
    # ticks can overlap, so the interval is enforced atomically here rather than
    # trusted from the enqueue. See Subscriber.claim_delivery_slot.
    return unless Subscriber.claim_delivery_slot(subscriber_id)

    Deliveries::SendNextNote.call(subscriber)
  end
end
