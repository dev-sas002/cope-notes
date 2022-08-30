# frozen_string_literal: true

module Deliveries
  module Channels
    # The contract every channel implements.
    class Base
      # Hand the note to the provider.
      #
      # @return [String, nil] a provider-side identifier, stored for reconciliation
      # @raise [Deliveries::TransientError] when the provider never saw the note
      def deliver(subscriber:, note:)
        raise NotImplementedError, "#{self.class}#deliver"
      end

      def name
        self.class.name.demodulize.underscore
      end
    end
  end
end
