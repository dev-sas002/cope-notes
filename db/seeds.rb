# frozen_string_literal: true

# Idempotent seed data, so a fresh boot has something to send and someone to
# send it to. Safe to re-run: both blocks only insert when the table is empty.

NOTES = [
  "You don't have to control your thoughts. You just have to stop letting them control you.",
  'Take your time healing, as long as you want. Nobody else knows what you have been through.',
  'One small crack does not mean that you are broken, it means that you were put to the test ' \
  'and you did not fall apart.',
  'Sometimes you climb out of bed in the morning and you think, I am not going to make it, ' \
  'but you laugh inside, remembering all the times you have felt that way.',
  'There is hope, even when your brain tells you there is not.',
  'Out of suffering have emerged the strongest souls; the most massive characters are seared with scars.',
  'Recovery is not one and done. It is a lifelong journey that takes place one day, one step at a time.',
  'Self-care is how you take your power back.',
  'Let your story go. Allow yourself to be present with who you are right now.',
  'My dark days made me strong. Or maybe I already was strong, and they made me prove it.'
].freeze

SUBSCRIBERS = [
  { name: 'Ada Lovelace',   email: 'ada@example.com',   is_active: true },
  { name: 'Grace Hopper',   email: 'grace@example.com', is_active: true },
  { name: 'Alan Turing',    email: 'alan@example.com',  is_active: true },
  { name: 'Katherine Johnson', email: 'katherine@example.com', is_active: false }
].freeze

if Message.count.zero?
  NOTES.each { |text| Message.create!(text: text) }
  Rails.logger.info("[seeds] created #{NOTES.size} notes")
end

if Subscriber.count.zero?
  SUBSCRIBERS.each { |attributes| Subscriber.create!(**attributes) }
  Rails.logger.info("[seeds] created #{SUBSCRIBERS.size} subscribers")
end

puts "Seeded: #{Message.count} notes, #{Subscriber.count} subscribers " \
     "(#{Subscriber.active.count} active)"
