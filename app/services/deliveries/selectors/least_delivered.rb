# frozen_string_literal: true

module Deliveries
  module Selectors
    # Prefers the notes the fewest subscribers have seen, so newly written notes
    # enter circulation immediately instead of waiting for a random draw.
    #
    # It reads the `deliveries_count` counter cache rather than aggregating the
    # join table, so it stays a single indexed `LIMIT 1` query. The tie-break is
    # random, otherwise every subscriber due in the same tick would be handed the
    # same note.
    class LeastDelivered < Base
      def call(subscriber)
        Message.deliverable
               .unsent_to(subscriber.id)
               .order(Arel.sql('messages.deliveries_count ASC, RANDOM()'))
               .first
      end
    end
  end
end
