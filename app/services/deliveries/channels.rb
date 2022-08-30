# frozen_string_literal: true

module Deliveries
  # Registry of delivery channels.
  #
  # A channel is anything that can put a note in front of a subscriber: email
  # today, SMS or a push notification tomorrow. Adding one means writing a class
  # that responds to `deliver(subscriber:, note:)` and registering it:
  #
  #   Deliveries::Channels.register(:sms, Deliveries::Channels::Sms)
  #
  # Nothing above the channel - not the job, not the selection strategy, not the
  # delivery service - has to change. `DELIVERY_CHANNEL` picks the one in use.
  module Channels
    UnknownChannel = Class.new(StandardError)

    @registry = {}

    class << self
      attr_reader :registry

      def register(name, channel_class)
        @registry[name.to_sym] = channel_class
      end

      def fetch(name = Deliveries.channel_name)
        klass = @registry.fetch(name.to_sym) do
          raise UnknownChannel, "no delivery channel registered as #{name.inspect} (registered: #{names.join(', ')})"
        end
        klass.new
      end

      def names
        @registry.keys
      end
    end
  end
end
