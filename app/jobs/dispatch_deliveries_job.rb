# frozen_string_literal: true

# The scheduled entry point: runs on the cron in config/sidekiq.yml and does
# nothing but fan the tick out. It holds no SMTP connection and no long
# transaction, so it can safely run on a queue of its own and never falls behind
# the delivery jobs it creates.
class DispatchDeliveriesJob < ApplicationJob
  queue_as :default

  def perform
    enqueued = Deliveries::Dispatcher.call
    Rails.logger.info("[deliveries] dispatched #{enqueued} subscriber(s)")
    enqueued
  end
end
