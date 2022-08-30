# frozen_string_literal: true

module Deliveries
  # Sends one subscriber the next note they have not seen.
  #
  # The sequence is **claim -> send -> confirm**, and each step exists for a
  # reason:
  #
  # * *Claim* is a plain INSERT into `subscriber_emails`. The unique index on
  #   (subscriber_id, message_id) is the lock: two workers racing on the same
  #   subscriber cannot both send the same note, because the loser's insert is
  #   rejected. No advisory lock, no SELECT ... FOR UPDATE, no extra round trip.
  #
  # * *Send* happens **outside** any transaction. The previous implementation
  #   wrapped the SMTP call in one, which meant a database connection and a row
  #   lock were held for the whole provider round trip - at a few hundred
  #   subscribers that alone exhausts the connection pool.
  #
  # * *Confirm* stamps `delivered_at` and `status`. A row that was claimed but
  #   never confirmed is therefore visible, instead of being indistinguishable
  #   from a successful delivery.
  #
  # The guarantee this buys: **a given note is sent to a given subscriber at
  # most once, and the database always records what actually happened.** A
  # channel that raises TransientError never handed the note over, so the claim
  # is released and the same note is offered again next tick. Any other error is
  # ambiguous - the provider may or may not have accepted it - so the claim is
  # kept in the `failed` state and the subscriber simply gets a different note
  # next time. For a product whose notes are interchangeable, losing one note is
  # strictly better than sending a duplicate.
  class SendNextNote
    def self.call(subscriber, **options)
      new(subscriber, **options).call
    end

    def initialize(subscriber, selector: Selectors.fetch, channel: Channels.fetch, clock: Time)
      @subscriber = subscriber
      @selector = selector
      @channel = channel
      @clock = clock
    end

    def call
      note = selector.call(subscriber)
      return Result.new(status: :skipped) if note.nil?

      claim = claim(note)
      return Result.new(status: :skipped, note: note) if claim.nil?

      send_and_confirm(claim, note)
    end

    private

    attr_reader :subscriber, :selector, :channel, :clock

    def claim(note)
      SubscriberEmail.create!(
        subscriber: subscriber,
        message: note,
        channel: channel.name,
        status: SubscriberEmail::CLAIMED
      )
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      # Another worker is already sending this note to this subscriber.
      nil
    end

    def send_and_confirm(claim, note)
      reference = channel.deliver(subscriber: subscriber, note: note)
      confirm(claim, reference)
      Result.new(status: :delivered, note: note)
    rescue TransientError => e
      claim.destroy
      log_failure(note, e, 'released for retry')
      Result.new(status: :released, note: note, error: e)
    rescue StandardError => e
      mark_failed(claim, e)
      log_failure(note, e, 'recorded as failed')
      Result.new(status: :failed, note: note, error: e)
    end

    def confirm(claim, reference)
      now = clock.current
      claim.update_columns(
        status: SubscriberEmail::DELIVERED,
        delivered_at: now,
        provider_reference: reference,
        updated_at: now
      )
      Subscriber.where(id: subscriber.id).update_all(last_delivered_at: now, updated_at: now)
    end

    def mark_failed(claim, error)
      claim.update_columns(
        status: SubscriberEmail::FAILED,
        failure_reason: "#{error.class}: #{error.message}".truncate(255),
        updated_at: clock.current
      )
    end

    def log_failure(note, error, disposition)
      Rails.logger.error(
        "[delivery] failed to send note #{note.id} to subscriber #{subscriber.id} " \
        "via #{channel.name}, #{disposition}: #{error.class}: #{error.message}"
      )
    end
  end
end
