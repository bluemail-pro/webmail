json.extract! message, :id, :from, :to, :subject, :body, :user_id, :created_at, :updated_at
json.url message_url(message, format: :json)
