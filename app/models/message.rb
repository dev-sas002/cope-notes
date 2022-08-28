# frozen_string_literal: true

# One short supportive note. `Message` is the name the public API uses, so the
# model keeps it; everything newer in the codebase calls them notes.
class Message < ApplicationRecord
  APPROVED = 'approved'
  FLAGGED  = 'flagged'
  REJECTED = 'rejected'
  REVIEW_STATUSES = [APPROVED, FLAGGED, REJECTED].freeze

  has_many :subscriber_emails, dependent: :destroy
  has_many :subscribers, through: :subscriber_emails

  validates :text, presence: true, length: { maximum: 500 }
  validates :review_status, inclusion: { in: REVIEW_STATUSES }

  # Notes a human should look at, but which are still safe to send.
  scope :flagged, -> { where(review_status: FLAGGED) }

  # Everything the delivery path is allowed to choose from. Only an outright
  # rejection withholds a note; a flag is a prompt for an editor, not a block.
  scope :deliverable, -> { where.not(review_status: REJECTED) }

  # Notes this subscriber has no delivery row for. Written as NOT EXISTS rather
  # than `where.not(id: subquery)` because NOT IN is not NULL-safe, and because
  # Postgres plans this as an anti-join straight off the unique index on
  # (subscriber_id, message_id).
  scope :unsent_to, lambda { |subscriber_id|
    where(
      'NOT EXISTS (SELECT 1 FROM subscriber_emails se ' \
      'WHERE se.message_id = messages.id AND se.subscriber_id = ?)',
      subscriber_id
    )
  }

  def record_review(verdict)
    assign_attributes(
      review_status: verdict.status,
      review_notes: [verdict.reviewer, verdict.notes].compact.join(': ').presence,
      reviewed_at: Time.current
    )
  end
end
