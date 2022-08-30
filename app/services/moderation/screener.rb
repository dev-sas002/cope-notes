# frozen_string_literal: true

module Moderation
  # Runs a note's text past a reviewer and returns a Verdict.
  #
  # Screening fails *open*: if the configured reviewer raises, the local
  # heuristic reviewer answers instead, and if that somehow fails too the note is
  # approved. Blocking note authoring because a third-party API is down would be
  # a worse outcome than letting a note reach a human editor, and the `flagged`
  # status exists so nothing slips by unnoticed.
  class Screener
    def self.call(text, **options)
      new(**options).call(text)
    end

    def initialize(reviewer: Moderation.default_reviewer, fallback: HeuristicReviewer.new)
      @reviewer = reviewer
      @fallback = fallback
    end

    def call(text)
      reviewer.review(text)
    rescue StandardError => e
      Rails.logger.warn("[moderation] #{reviewer.class} failed (#{e.class}: #{e.message}); falling back")
      fallback_review(text)
    end

    private

    attr_reader :reviewer, :fallback

    def fallback_review(text)
      fallback.review(text)
    rescue StandardError => e
      Rails.logger.error("[moderation] fallback reviewer failed (#{e.class}: #{e.message}); approving unscreened")
      Verdict.new(status: Message::APPROVED, notes: 'screening unavailable', reviewer: 'none')
    end
  end
end
