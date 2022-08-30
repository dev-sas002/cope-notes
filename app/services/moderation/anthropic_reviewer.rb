# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module Moderation
  # Reviews note text with Claude via the Anthropic Messages API.
  #
  # This talks to the REST endpoint with Net::HTTP rather than the official
  # `anthropic` gem, for one reason: the gem requires Ruby >= 3.2 and this
  # application is pinned to Ruby 3.0.2 by Rails 6.1. Should the app move to a
  # newer Ruby, swapping the body of #review for the SDK is a contained change -
  # the Verdict contract is what the rest of the app depends on.
  #
  # It is never reached unless ANTHROPIC_API_KEY is set, and Screener falls back
  # to the local reviewer if this one raises, so a missing key, a rate limit or
  # an outage all degrade to the offline behaviour rather than blocking writes.
  class AnthropicReviewer
    ENDPOINT = URI('https://api.anthropic.com/v1/messages')
    API_VERSION = '2023-06-01'
    DEFAULT_MODEL = 'claude-opus-5'
    MAX_TOKENS = 1_024
    DEFAULT_TIMEOUT = 10

    SYSTEM_PROMPT = <<~PROMPT
      You screen short supportive notes that a mental-health service sends to
      subscribers who are struggling. Judge only the note text you are given.

      Answer with a single JSON object and nothing else:
        {"status": "approved" | "flagged" | "rejected", "notes": "<one short sentence>"}

      rejected - the note could cause harm: it encourages self-harm or suicide,
                 gives medical, medication or dosage advice, promises a cure, or
                 is cruel to the reader.
      flagged  - the note is not harmful but a human should look at it: it is
                 dismissive, preachy, references self-harm, or is off-topic.
      approved - the note is a supportive message that is safe to send.
    PROMPT

    class ReviewError < StandardError; end

    def self.api_key
      ENV['ANTHROPIC_API_KEY'].presence
    end

    def self.configured?
      api_key.present?
    end

    def initialize(api_key: self.class.api_key, model: ENV.fetch('ANTHROPIC_MODEL', DEFAULT_MODEL),
                   timeout: Deliveries.env_integer('ANTHROPIC_TIMEOUT_SECONDS', DEFAULT_TIMEOUT))
      raise ReviewError, 'ANTHROPIC_API_KEY is not set' if api_key.blank?

      @api_key = api_key
      @model = model
      @timeout = timeout
    end

    def review(text)
      parsed = parse(request(text))
      Verdict.new(
        status: normalise(parsed['status']),
        notes: parsed['notes'],
        reviewer: "anthropic/#{model}"
      )
    end

    private

    attr_reader :api_key, :model, :timeout

    def request(text)
      http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
      http.use_ssl = true
      http.open_timeout = timeout
      http.read_timeout = timeout

      response = http.request(post_request(text))
      raise ReviewError, "Anthropic API returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end

    def post_request(text)
      request = Net::HTTP::Post.new(ENDPOINT)
      request['content-type'] = 'application/json'
      request['x-api-key'] = api_key
      request['anthropic-version'] = API_VERSION
      request.body = JSON.generate(
        model: model,
        max_tokens: MAX_TOKENS,
        system: SYSTEM_PROMPT,
        # A short classification does not need deep reasoning; low effort keeps
        # the call cheap and fast while leaving thinking enabled.
        output_config: { effort: 'low' },
        messages: [{ role: 'user', content: "Note text:\n#{text}" }]
      )
      request
    end

    # The model is asked for bare JSON, but a stray sentence around it should not
    # take the endpoint down - pull out the first JSON object and parse that.
    def parse(body)
      payload = JSON.parse(body)
      text = Array(payload['content']).filter_map { |block| block['text'] if block['type'] == 'text' }.join
      json = text[/\{.*\}/m]
      raise ReviewError, 'Anthropic API returned no JSON object' if json.nil?

      JSON.parse(json)
    rescue JSON::ParserError => e
      raise ReviewError, "could not parse Anthropic response: #{e.message}"
    end

    def normalise(status)
      candidate = status.to_s.downcase
      return candidate if Message::REVIEW_STATUSES.include?(candidate)

      raise ReviewError, "Anthropic API returned unknown status #{status.inspect}"
    end
  end
end
