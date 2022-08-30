# frozen_string_literal: true

# Everything involved in getting one note in front of one subscriber.
#
# The two entry points are:
#
#   Deliveries::Dispatcher     - fans a scheduler tick out into one job per due
#                                subscriber (called by DispatchDeliveriesJob)
#   Deliveries::SendNextNote   - claims, sends and records a single note
#                                (called by DeliverNoteJob)
#
# Everything else in this namespace is a collaborator of those two: a selection
# strategy decides *which* note, a channel decides *how* it travels.
module Deliveries
  # Raised by a channel when the note was definitely **not** handed to the
  # provider - a refused connection, a timeout before the payload was accepted.
  # The claim is released so the same note is retried on the next tick.
  TransientError = Class.new(StandardError)

  DEFAULT_BATCH_SIZE = 1_000
  DEFAULT_INTERVAL_MINUTES = 1
  DEFAULT_SPREAD_SECONDS = 0

  module_function

  # How many subscriber ids one keyset page of the dispatcher holds. This is the
  # dispatcher's memory ceiling, whether the table has 100 rows or 100 million.
  def batch_size
    env_integer('DELIVERY_BATCH_SIZE', DEFAULT_BATCH_SIZE)
  end

  # Minimum gap between two notes for the same subscriber. The default of one
  # minute reproduces the original behaviour; production deployments set this to
  # 1440 for a daily note.
  def interval
    env_integer('DELIVERY_INTERVAL_MINUTES', DEFAULT_INTERVAL_MINUTES).minutes
  end

  # Window, in seconds, over which a tick's jobs are randomly scattered. Zero
  # enqueues everything immediately; anything higher trades a little latency for
  # a flat load profile on the SMTP provider.
  def spread_seconds
    env_integer('DELIVERY_SPREAD_SECONDS', DEFAULT_SPREAD_SECONDS, allow_zero: true)
  end

  def channel_name
    ENV.fetch('DELIVERY_CHANNEL', 'email').to_sym
  end

  def selection_strategy
    ENV.fetch('NOTE_SELECTION_STRATEGY', 'random_unsent').to_sym
  end

  def env_integer(key, fallback, allow_zero: false)
    parsed = Integer(ENV.fetch(key, nil), exception: false)
    return fallback if parsed.nil? || parsed.negative?
    return fallback if parsed.zero? && !allow_zero

    parsed
  end
end
