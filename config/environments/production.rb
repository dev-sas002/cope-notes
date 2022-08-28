require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true

  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.public_file_server.headers = { 'cache-control' => "public, max-age=#{1.year.to_i}" }

  # Log to STDOUT with the request id attached, at info unless told otherwise.
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.logger($stdout)
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info')
  config.silence_healthcheck_path = '/up'

  config.active_support.report_deprecations = false

  # Delivery settings are environment-specific; point SMTP_* at your provider.
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch('SMTP_ADDRESS', 'localhost'),
    port: ENV.fetch('SMTP_PORT', 587).to_i,
    user_name: ENV.fetch('SMTP_USERNAME', nil),
    password: ENV.fetch('SMTP_PASSWORD', nil),
    authentication: ENV['SMTP_USERNAME'].present? ? :plain : nil,
    enable_starttls_auto: true
  }.compact

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]
end
