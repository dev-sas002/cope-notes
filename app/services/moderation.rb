# frozen_string_literal: true

# Screening of note text before it can ever reach a subscriber.
#
# Cope Notes go to people who are having a hard time, so a note that is
# dismissive, that gives medical or medication advice, or that could read as
# encouragement to self-harm must never be sent. Screening runs whenever a note
# is written or edited through the API and stamps `messages.review_status`; the
# delivery path only ever selects from notes that are not `rejected`.
module Moderation
  module_function

  # The reviewer used when nothing is injected: the Anthropic reviewer when an
  # API key is configured, the local keyword reviewer otherwise. The app is
  # fully functional - and the test suite passes - with no key set.
  def default_reviewer
    AnthropicReviewer.configured? ? AnthropicReviewer.new : HeuristicReviewer.new
  end
end
