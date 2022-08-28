# frozen_string_literal: true

module Deliveries
  # The outcome of one delivery attempt. Returned rather than raised so the
  # caller can count outcomes without rescuing control flow.
  #
  #   :delivered - the channel accepted the note and the row is confirmed
  #   :skipped   - nothing to do (no unsent note, or another worker claimed it)
  #   :released  - a transient failure; the claim was rolled back and the same
  #                note will be offered again on the next tick
  #   :failed    - the channel raised something we cannot classify; the claim is
  #                kept in the `failed` state so this note is never retried for
  #                this subscriber
  class Result
    STATUSES = %i[delivered skipped released failed].freeze

    attr_reader :status, :note, :error

    def initialize(status:, note: nil, error: nil)
      raise ArgumentError, "unknown delivery status #{status.inspect}" unless STATUSES.include?(status)

      @status = status
      @note = note
      @error = error
      freeze
    end

    STATUSES.each do |candidate|
      define_method(:"#{candidate}?") { status == candidate }
    end

    def to_s
      [status, note&.id, error&.message].compact.join(' ')
    end
  end
end
