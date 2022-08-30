# frozen_string_literal: true

class SubscriberEmail < ApplicationRecord
  belongs_to :subscriber
  belongs_to :message

  validates :subscriber, presence: true
  validates :message, presence: true
  validates :subscriber_id, uniqueness: { scope: %i[message_id] }
end
