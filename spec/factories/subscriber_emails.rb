# frozen_string_literal: true

FactoryBot.define do
  factory :subscriber_email do
    subscriber
    message
  end
end
