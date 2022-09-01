# frozen_string_literal: true

class MessageSerializer < ActiveModel::Serializer
  has_many :subscribers

  attributes :id, :text, :review_status, :deliveries_count
end
