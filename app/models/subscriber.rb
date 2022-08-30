# frozen_string_literal: true

class Subscriber < ApplicationRecord
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  has_many :subscriber_emails, dependent: :destroy
  has_many :messages, through: :subscriber_emails

  validates :is_active, inclusion: { in: [true, false] }
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 50 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }

  before_validation :normalize_email

  scope :active, -> { where(is_active: true) }

  # Active subscribers who have waited at least one delivery interval since
  # their last note. The dispatcher pages over this with keyset pagination, and
  # `index_subscribers_due_for_delivery` covers it exactly.
  scope :due, lambda { |now = Time.current, interval = Deliveries.interval|
    active.where('last_delivered_at IS NULL OR last_delivered_at <= ?', now - interval)
  }

  # Atomically reserves this subscriber's next delivery slot.
  #
  # Two dispatcher ticks can overlap - a slow tick, a manual `deliveries:tick`,
  # a second worker fleet - and the enqueued jobs would then both find the
  # subscriber due and both send. The predicate and the write are therefore a
  # single conditional UPDATE: Postgres serialises the two statements, the
  # second one matches no rows, and exactly one caller is told to send.
  #
  # Moving the cursor before the send, rather than after, is deliberate. It is a
  # rate limit, not a delivery record: the truth about what was sent lives in
  # subscriber_emails. Losing a slot to a failed send costs one interval's
  # silence, whereas a cursor that only moves on success lets every retry and
  # every racing tick send again.
  #
  # @return [Boolean] true if this caller won the slot
  def self.claim_delivery_slot(id, now: Time.current, interval: Deliveries.interval)
    # rubocop:disable Rails/SkipsModelValidations -- the point is the single
    # conditional UPDATE; loading the record first would reopen the race.
    due(now, interval).where(id: id).update_all(last_delivered_at: now, updated_at: now) == 1
    # rubocop:enable Rails/SkipsModelValidations
  end

  # Flips the subscription on or off. `update!` rather than `toggle!` so the
  # record is still validated on the way through.
  def change_status
    update(is_active: !is_active)
  end

  private

  # The unique index on subscribers.email is case sensitive, so addresses are
  # stored normalised to keep "User@Example.com" and "user@example.com" from
  # both subscribing (and both receiving mail).
  def normalize_email
    self.email = email.strip.downcase if email.present?
  end
end
