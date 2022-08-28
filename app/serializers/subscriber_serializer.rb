# frozen_string_literal: true

class SubscriberSerializer < ActiveModel::Serializer
  has_many :messages

  attributes :id, :name, :email, :is_active, :last_delivered_at
end
