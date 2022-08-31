# frozen_string_literal: true

# Wiring for the two extension points in the delivery pipeline.
#
# Registration happens in `to_prepare` rather than at the top level so the
# registries are repopulated after every code reload in development - the
# registry module is itself autoloaded and is discarded on reload.
Rails.application.config.to_prepare do
  Deliveries::Channels.register(:email, Deliveries::Channels::Email)
  Deliveries::Channels.register(:log, Deliveries::Channels::Log)

  Deliveries::Selectors.register(:random_unsent, Deliveries::Selectors::RandomUnsent)
  Deliveries::Selectors.register(:least_delivered, Deliveries::Selectors::LeastDelivered)
end
