require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.enable_reloading = false
  # Eager load only when the whole suite runs in CI-like conditions; a single
  # spec file should not pay for loading the whole app.
  config.eager_load = ENV['EAGER_LOAD'].present?

  config.public_file_server.headers = { 'cache-control' => "public, max-age=#{1.hour.to_i}" }

  config.consider_all_requests_local = true
  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = :none

  config.action_controller.allow_forgery_protection = false

  # Jobs are asserted on, not run through Redis. Specs that want a job to run
  # use ActiveJob::TestHelper#perform_enqueued_jobs.
  config.active_job.queue_adapter = :test

  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { host: 'www.example.com' }

  config.active_support.deprecation = :stderr
  config.action_controller.raise_on_missing_callback_actions = true
end
