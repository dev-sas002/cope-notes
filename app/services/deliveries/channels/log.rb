# frozen_string_literal: true

module Deliveries
  module Channels
    # Writes the note to the Rails log instead of sending it.
    #
    # This is the second real implementation that keeps the channel seam honest,
    # and it is what `DELIVERY_CHANNEL=log` uses to load-test the dispatcher
    # without pointing a benchmark at a real SMTP server.
    class Log < Base
      def deliver(subscriber:, note:)
        reference = "log-#{SecureRandom.hex(8)}"
        Rails.logger.info(
          "[delivery] channel=log subscriber=#{subscriber.id} note=#{note.id} " \
          "reference=#{reference} text=#{note.text.truncate(80).inspect}"
        )
        reference
      end
    end
  end
end
