# frozen_string_literal: true

FactoryBot.define do
  factory :subscriber_email do
    subscriber
    message
    status { SubscriberEmail::DELIVERED }
    delivered_at { Time.current }

    trait :claimed do
      status { SubscriberEmail::CLAIMED }
      delivered_at { nil }
    end

    trait :failed do
      status { SubscriberEmail::FAILED }
      delivered_at { nil }
      failure_reason { 'StandardError: mailbox unavailable' }
    end
  end
end
