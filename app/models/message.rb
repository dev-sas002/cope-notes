# frozen_string_literal: true

class Message < ApplicationRecord
  has_many :subscriber_emails, dependent: :destroy
  has_many :subscribers, through: :subscriber_emails

  validates :text, presence: true, length: { maximum: 500 }
end
