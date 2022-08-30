# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    text { Faker::Lorem.characters(number: 10) }
  end
end
