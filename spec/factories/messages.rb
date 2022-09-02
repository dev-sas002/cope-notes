# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    text { Faker::Lorem.characters(number: 10) }

    trait :flagged do
      review_status { Message::FLAGGED }
    end

    trait :rejected do
      review_status { Message::REJECTED }
    end
  end
end
