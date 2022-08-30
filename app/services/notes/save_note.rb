# frozen_string_literal: true

module Notes
  # Creates or updates a note, screening its text on the way in.
  #
  # This exists so the controller stays an HTTP adapter: it parses parameters and
  # renders, and the rule "text that changes is re-screened before it is stored"
  # lives somewhere it can be unit tested without a request.
  class SaveNote
    def self.call(note, attributes, **options)
      new(note, attributes, **options).call
    end

    def initialize(note, attributes, screener: Moderation::Screener.new)
      @note = note
      @attributes = attributes
      @screener = screener
    end

    # @return [Boolean] whether the note was saved
    def call
      note.assign_attributes(attributes)
      note.record_review(screener.call(note.text)) if rescreen?
      note.save
    end

    private

    attr_reader :note, :attributes, :screener

    def rescreen?
      note.text.present? && note.text_changed?
    end
  end
end
