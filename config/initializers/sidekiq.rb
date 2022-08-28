url = ENV['REDIS_URL'] || 'redis://127.0.0.1:6379/0'
connection = proc { Redis.new(url: url) }

Sidekiq.configure_server do |config|
  config.redis = { url: url, network_timeout: 10 }
end

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 2, &connection)
end

# The Sidekiq dashboard mounted at /sidekiq exposes (and can manipulate) job
# data, so it is put behind HTTP basic auth whenever credentials are configured.
# This lives in an initializer rather than in routes.rb so the middleware is not
# stacked again every time the routes are reloaded in development.
if ENV['SIDEKIQ_WEB_USERNAME'].present? && ENV['SIDEKIQ_WEB_PASSWORD'].present?
  require 'sidekiq/web'

  Sidekiq::Web.use(Rack::Auth::Basic, 'Sidekiq') do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(username, ENV['SIDEKIQ_WEB_USERNAME']) &
      ActiveSupport::SecurityUtils.secure_compare(password, ENV['SIDEKIQ_WEB_PASSWORD'])
  end
end
