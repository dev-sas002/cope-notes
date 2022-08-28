# frozen_string_literal: true

module Deliveries
  # Registry of note-selection strategies.
  #
  # A strategy answers one question - "which note should this subscriber get
  # next?" - and returns a Message or nil. Keeping it behind a registry means
  # an engagement-driven or personalised strategy can be dropped in without
  # touching the delivery path. `NOTE_SELECTION_STRATEGY` picks the one in use.
  module Selectors
    UnknownStrategy = Class.new(StandardError)

    @registry = {}

    class << self
      attr_reader :registry

      def register(name, strategy_class)
        @registry[name.to_sym] = strategy_class
      end

      def fetch(name = Deliveries.selection_strategy)
        klass = @registry.fetch(name.to_sym) do
          raise UnknownStrategy, "no selection strategy registered as #{name.inspect} (registered: #{names.join(', ')})"
        end
        klass.new
      end

      def names
        @registry.keys
      end
    end
  end
end
