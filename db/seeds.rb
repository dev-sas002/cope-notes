# frozen_string_literal: true

# Idempotent seed data, so a fresh boot has something to send and someone to
# send it to. Safe to re-run: both blocks only insert when the table is empty.

# Demo content only. The notes were written for this project, and every
# subscriber is a made-up person at the reserved example.com domain.
notes = [
  'You do not have to have it all figured out today. Getting through this hour is enough.',
  'Rest is not something you have to earn.',
  'A hard day is not the same as a hard life. This one will pass too.',
  'It is all right to ask for help, and it is all right to ask more than once.',
  'Be as patient with yourself as you would be with a friend who felt this way.',
  'Small things count: a glass of water, an open window, five slow breaths.',
  'You have made it through every difficult day so far.',
  'Feelings are visitors. You can let them sit for a while without letting them stay.',
  'Progress is allowed to be quiet, slow and invisible to everyone but you.',
  'Whatever today looked like, you are still here, and that matters.'
]

subscribers = [
  { name: 'Robin Demo',  email: 'robin.demo@example.com',  is_active: true },
  { name: 'Sam Sample',  email: 'sam.sample@example.com',  is_active: true },
  { name: 'Jules Test',  email: 'jules.test@example.com',  is_active: true },
  { name: 'Kit Example', email: 'kit.example@example.com', is_active: false }
]

unless Message.exists?
  notes.each { |text| Message.create!(text: text) }
  Rails.logger.info("[seeds] created #{notes.size} notes")
end

unless Subscriber.exists?
  subscribers.each { |attributes| Subscriber.create!(**attributes) }
  Rails.logger.info("[seeds] created #{subscribers.size} subscribers")
end

puts "Seeded: #{Message.count} notes, #{Subscriber.count} subscribers " \
     "(#{Subscriber.active.count} active)"
