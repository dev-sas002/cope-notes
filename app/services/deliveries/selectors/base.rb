# frozen_string_literal: true

module Deliveries
  module Selectors
    # The contract every selection strategy implements.
    class Base
      # @return [Message, nil] the next note for this subscriber
      def call(subscriber)
        raise NotImplementedError, "#{self.class}#call"
      end

      def name
        self.class.name.demodulize.underscore
      end
    end
  end
end
