json.extract! message, :id, :email, :name, :created_at, :updated_at
json.url message_url(message, format: :json)
