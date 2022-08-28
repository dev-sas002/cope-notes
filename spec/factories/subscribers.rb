# frozen_string_literal: true

FactoryBot.define do
  factory :subscriber do
    email { Faker::Internet.email }
    name { Faker::Name.name }
  end
end
