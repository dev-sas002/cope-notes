# frozen_string_literal: true

module Moderation
  # Deterministic, offline reviewer.
  #
  # It is deliberately narrow: it catches the categories that are unambiguous in
  # plain text and leaves everything else approved. It exists so the product has
  # a real safety floor with no API key, no network and no cost - and so the
  # test suite never needs to reach the internet.
  class HeuristicReviewer
    REJECT_PATTERNS = {
      'encourages self-harm' => /\b(kill yourself|end it all|hurt yourself|harm yourself)\b/i,
      'gives medication advice' =>
        /\b(stop taking|double(?: up on)?|skip) your (?:meds|medication|antidepressants|pills)\b/i
    }.freeze

    FLAG_PATTERNS = {
      'dismissive of the reader' => /\b(just get over it|stop being (?:so )?(?:sad|dramatic)|others have it worse)\b/i,
      'mentions self-harm' => /\b(suicide|self[- ]harm)\b/i
    }.freeze

    def review(text)
      value = text.to_s

      matched = REJECT_PATTERNS.find { |_reason, pattern| value.match?(pattern) }
      return verdict(Message::REJECTED, matched.first) if matched

      matched = FLAG_PATTERNS.find { |_reason, pattern| value.match?(pattern) }
      return verdict(Message::FLAGGED, matched.first) if matched

      verdict(Message::APPROVED, 'no keyword matches')
    end

    private

    def verdict(status, reason)
      Verdict.new(status: status, notes: reason, reviewer: 'heuristic')
    end
  end
end
