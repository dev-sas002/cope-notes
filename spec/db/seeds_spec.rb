require 'rails_helper'

# The compose entrypoint seeds on every boot, so seeding has to be safe to repeat.
RSpec.describe 'db/seeds.rb' do # rubocop:disable RSpec/DescribeClass
  def seed
    load Rails.root.join('db/seeds.rb')
  end

  it 'creates demo notes and subscribers once, however often it runs' do
    expect { seed }.to output(/Seeded: 10 notes, 4 subscribers \(3 active\)/).to_stdout
    expect { seed }.to output(/Seeded: 10 notes, 4 subscribers/).to_stdout

    expect(Message.count).to eq(10)
    expect(Subscriber.count).to eq(4)
  end

  it 'uses only reserved example.com addresses' do
    expect { seed }.to output.to_stdout

    expect(Subscriber.pluck(:email)).to all(end_with('@example.com'))
  end
end
