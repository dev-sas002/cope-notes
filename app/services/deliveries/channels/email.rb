# frozen_string_literal: true

require 'net/smtp'

module Deliveries
  module Channels
    # Sends the note as an email through Action Mailer.
    class Email < Base
      # Failures that mean the provider never accepted the note, so offering the
      # same note again is safe. Anything outside this list is treated as
      # ambiguous: we cannot prove the note was not delivered, so we do not
      # retry it.
      TRANSIENT_ERRORS = [
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Errno::EHOSTUNREACH,
        Errno::ENETUNREACH,
        Errno::ETIMEDOUT,
        IOError,
        Net::OpenTimeout,
        Net::ReadTimeout,
        Net::SMTPAuthenticationError,
        Net::SMTPServerBusy,
        SocketError,
        Timeout::Error
      ].freeze

      def deliver(subscriber:, note:)
        mail = MessageMailer.with(subscriber: subscriber, message: note).new_message_email
        mail.deliver_now
        mail.message_id
      rescue *TRANSIENT_ERRORS => e
        raise TransientError, "#{e.class}: #{e.message}"
      end
    end
  end
end
