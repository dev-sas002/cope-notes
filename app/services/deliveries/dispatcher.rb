# frozen_string_literal: true

module Deliveries
  # Turns one scheduler tick into one background job per due subscriber.
  #
  # The old job did the whole batch inline: a single thread walking every active
  # subscriber and making a blocking SMTP call for each. At ~150 ms per send that
  # overruns a once-a-minute schedule at roughly 400 subscribers, and every
  # subscriber after the slow one waits behind it.
  #
  # Fanning out fixes both problems at once - the sends run across every Sidekiq
  # thread in the fleet, and one hung provider connection delays exactly one
  # subscriber.
  #
  # Subscribers are walked by keyset pagination (`id > cursor ORDER BY id LIMIT n`)
  # over a partial index covering exactly the due set, so a tick costs what the
  # due set costs, not what the table costs, and memory is capped at `batch_size`
  # ids no matter how large the table grows.
  class Dispatcher
    def self.call(**options)
      new(**options).call
    end

    def initialize(now: Time.current, batch_size: Deliveries.batch_size, spread_seconds: Deliveries.spread_seconds)
      @now = now
      @batch_size = batch_size
      @spread_seconds = spread_seconds
    end

    # @return [Integer] how many subscribers were enqueued
    def call
      cursor = 0
      enqueued = 0

      loop do
        ids = page(cursor)
        break if ids.empty?

        ids.each { |id| enqueue(id) }
        enqueued += ids.size
        cursor = ids.last
        break if ids.size < batch_size
      end

      enqueued
    end

    private

    attr_reader :now, :batch_size, :spread_seconds

    def page(cursor)
      Subscriber.due(now)
                .where('subscribers.id > ?', cursor)
                .order(:id)
                .limit(batch_size)
                .pluck(:id)
    end

    def enqueue(subscriber_id)
      return DeliverNoteJob.perform_later(subscriber_id) if spread_seconds.zero?

      DeliverNoteJob.set(wait: rand(spread_seconds).seconds).perform_later(subscriber_id)
    end
  end
end
