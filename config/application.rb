require_relative 'boot'

require 'rails'
# Only the frameworks the API, the mailer and the jobs actually use. Active
# Storage, Action Cable, Action Text, Action Mailbox and the asset pipeline were
# generator leftovers and are not loaded.
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CopeNotes
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])

    config.active_job.queue_adapter = :sidekiq

  end
end
