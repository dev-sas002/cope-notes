class SubscriberSerializer < ActiveModel::Serializer
  has_many :messages

  attributes :id, :name, :email, :is_active
end
