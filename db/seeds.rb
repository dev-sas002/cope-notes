# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Message.count.zero?
  [
    "You don't have to control your thoughts. You just have to stop letting them control you.",
    "Take your time healing, as long as you want. Nobody else knows what you've been through. How could they know how
      long it will take to heal you?",
    "One small crack does not mean that you are broken, it means that you were put to the test and you didn't
      fall apart.",
    "Sometimes you climb out of bed in the morning and you think, I'm not going to make it, but you laugh
      inside — remembering all the times you've felt that way.",
    "There is hope, even when your brain tells you there isn't.",
    'Out of suffering have emerged the strongest souls; the most massive characters are seared with scars.',
    'Recovery is not one and done. It is a lifelong journey that takes place one day, one step at a time.',
    'Self-care is how you take your power back.',
    'Let your story go. Allow yourself to be present with who you are right now.',
    'My dark days made me strong. Or maybe I already was strong, and they made me prove it.'
  ].each do |message|
    Message.create!(text: message)
  end
end

p '10 messages added successfully!'
