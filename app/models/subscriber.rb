# frozen_string_literal: true

class Subscriber < ApplicationRecord
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  has_many :subscriber_emails, dependent: :destroy
  has_many :messages, through: :subscriber_emails

  validates :is_active, inclusion: { in: [ true, false ] }
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 50 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true

  scope :active, -> { where(is_active: true) }

  def change_status
    toggle!(:is_active)
  end
end
