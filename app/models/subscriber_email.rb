# frozen_string_literal: true

# One delivery of one note to one subscriber.
#
# The unique index on (subscriber_id, message_id) is the exactly-once mechanism:
# the row is inserted *before* the note is sent, so the insert itself is the
# claim two racing workers compete for. `status` then records what happened to
# that claim - see Deliveries::SendNextNote for the full sequence.
class SubscriberEmail < ApplicationRecord
  CLAIMED   = 'claimed'
  DELIVERED = 'delivered'
  FAILED    = 'failed'
  STATUSES  = [CLAIMED, DELIVERED, FAILED].freeze

  belongs_to :subscriber
  belongs_to :message, counter_cache: :deliveries_count

  validates :subscriber_id, uniqueness: { scope: %i[message_id] }
  validates :status, inclusion: { in: STATUSES }

  scope :delivered, -> { where(status: DELIVERED) }
  scope :failed, -> { where(status: FAILED) }
  # Claimed but never confirmed: the worker died between the insert and the
  # send, so these are the rows worth alerting on.
  scope :unconfirmed, -> { where(status: CLAIMED) }
end
