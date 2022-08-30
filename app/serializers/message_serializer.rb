class MessageSerializer < ActiveModel::Serializer
  has_many :subscribers

  attributes :id, :text
end
