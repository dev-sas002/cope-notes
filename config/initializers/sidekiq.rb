url = ENV['REDIS_URL'] || 'redis://127.0.0.1:6379/0'
connection = proc { Redis.new(url: url) }

Sidekiq.configure_server do |config|
  config.redis = { network_timeout: 10 }
end

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 2, &connection)
end
