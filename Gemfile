source 'https://rubygems.org'

ruby '~> 3.4.0'

gem 'rails', '~> 8.1.0'
gem 'pg', '~> 1.5'
gem 'puma', '>= 6.4'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false
gem 'active_model_serializers', '~> 0.10.15'

# Background delivery: the scheduler lives inside the Sidekiq process.
gem 'sidekiq', '~> 8.0'
gem 'sidekiq-scheduler', '~> 6.0'

# Model-based note screening; only used when ANTHROPIC_API_KEY is set.
gem 'anthropic', '~> 1.0'

group :development do
  # Captures outgoing mail and serves it at /letter_opener.
  gem 'letter_opener_web', '~> 3.0'
end

group :test do
  gem 'rspec-rails', '~> 8.0'
  gem 'shoulda-matchers', '~> 6.0'
  gem 'factory_bot_rails'
  gem 'faker'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]
