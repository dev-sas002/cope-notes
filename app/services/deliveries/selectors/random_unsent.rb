# frozen_string_literal: true

module Deliveries
  module Selectors
    # Picks a uniformly random note the subscriber has not received.
    #
    # This is one `LIMIT 1` query planned as an anti-join against the unique
    # index on (subscriber_id, message_id). Nothing about it grows with the
    # number of notes the subscriber has already had, which is the whole point:
    # the previous implementation loaded every note and every delivery row for
    # every subscriber into Ruby on every tick.
    class RandomUnsent < Base
      def call(subscriber)
        Message.deliverable
               .unsent_to(subscriber.id)
               .order(Arel.sql('RANDOM()'))
               .first
      end
    end
  end
end
