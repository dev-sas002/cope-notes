# frozen_string_literal: true

module Moderation
  # What a reviewer decided about a piece of note text.
  class Verdict
    attr_reader :status, :notes, :reviewer

    def initialize(status:, notes: nil, reviewer: nil)
      raise ArgumentError, "unknown review status #{status.inspect}" unless Message::REVIEW_STATUSES.include?(status)

      @status = status
      @notes = notes.presence
      @reviewer = reviewer
      freeze
    end

    def rejected?
      status == Message::REJECTED
    end
  end
end
