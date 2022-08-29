# frozen_string_literal: true

class SendMessageJob < ActiveJob::Base
  # The name of the queue to put this job into
  queue_as :default

  def perform
    message_pool = Message.all.index_by(&:id)
    return if message_pool.empty?

    Subscriber.active.includes(:messages).find_each do |subscriber|
      sent_message_ids = subscriber.message_ids
      available_message_ids = message_pool.keys - sent_message_ids
      next if available_message_ids.empty?

      message_to_send = message_pool[available_message_ids.sample]
      SubscriberEmail.create!(subscriber: subscriber, message: message_to_send)
      MessageMailer.with(subscriber: subscriber, message: message_to_send).new_message_email.deliver_now
    end
  end
end
