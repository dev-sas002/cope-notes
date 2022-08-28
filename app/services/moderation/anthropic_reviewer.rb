# frozen_string_literal: true

module Moderation
  # Reviews note text with Claude through the official `anthropic` gem.
  #
  # It is never reached unless ANTHROPIC_API_KEY is set, and Screener falls back
  # to the local reviewer if this one raises, so a missing key, a rate limit or
  # an outage all degrade to the offline behaviour rather than blocking writes.
  class AnthropicReviewer
    DEFAULT_MODEL = 'claude-opus-5-5'
    MAX_TOKENS = 1_024
    DEFAULT_TIMEOUT = 10
    # The text under review can itself be about self-harm, which is exactly the
    # material a safety classifier may decline. Server-side fallback lets
    # another model answer in the same call instead of the review being lost.
    FALLBACK_BETA = 'server-side-fallback-2026-07-01'

    SYSTEM_PROMPT = <<~PROMPT
      You screen short supportive notes that a mental-health service sends to
      subscribers who are struggling. Judge only the note text you are given.

      rejected - the note could cause harm: it encourages self-harm or suicide,
                 gives medical, medication or dosage advice, promises a cure, or
                 is cruel to the reader.
      flagged  - the note is not harmful but a human should look at it: it is
                 dismissive, preachy, references self-harm, or is off-topic.
      approved - the note is a supportive message that is safe to send.

      Put one short sentence explaining the decision in "notes".
    PROMPT

    # Structured output: the API guarantees the reply matches this schema.
    VERDICT_SCHEMA = {
      type: 'object',
      properties: {
        status: { type: 'string', enum: Message::REVIEW_STATUSES },
        notes: { type: 'string' }
      },
      required: %w[status notes],
      additionalProperties: false
    }.freeze

    class ReviewError < StandardError; end

    def self.api_key
      ENV['ANTHROPIC_API_KEY'].presence
    end

    def self.configured?
      api_key.present?
    end

    def initialize(api_key: self.class.api_key, model: ENV.fetch('ANTHROPIC_MODEL', DEFAULT_MODEL), client: nil)
      raise ReviewError, 'ANTHROPIC_API_KEY is not set' if api_key.blank? && client.nil?

      @model = model
      # One retry at most: a writer is waiting on this request, and the
      # heuristic reviewer is a perfectly good answer when the API is slow.
      @client = client || Anthropic::Client.new(
        api_key: api_key,
        max_retries: 1,
        timeout: Deliveries.env_integer('ANTHROPIC_TIMEOUT_SECONDS', DEFAULT_TIMEOUT)
      )
    end

    def review(text)
      parsed = parse(request(text))
      Verdict.new(status: parsed.fetch('status'), notes: parsed['notes'], reviewer: "anthropic/#{model}")
    end

    private

    attr_reader :client, :model

    def request(text)
      client.beta.messages.create(
        model: model,
        max_tokens: MAX_TOKENS,
        system_: SYSTEM_PROMPT,
        # A short classification does not need deep reasoning.
        output_config: { effort: :low, format_: { type: :json_schema, schema: VERDICT_SCHEMA } },
        messages: [{ role: 'user', content: "Note text:\n#{text}" }],
        fallbacks: :default,
        betas: [FALLBACK_BETA]
      )
    end

    def parse(response)
      raise ReviewError, 'Anthropic API declined to review this note' if response.stop_reason == :refusal

      text = response.content.filter_map { |block| block.text if block.type == :text }.join
      parsed = JSON.parse(text)
      return parsed if Message::REVIEW_STATUSES.include?(parsed['status'])

      raise ReviewError, "Anthropic API returned unknown status #{parsed['status'].inspect}"
    rescue JSON::ParserError => e
      raise ReviewError, "could not parse Anthropic response: #{e.message}"
    end
  end
end
