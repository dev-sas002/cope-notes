require 'rails_helper'

# The schedule is the only thing that ever starts a delivery, and a misplaced
# key in config/sidekiq.yml is silently ignored by sidekiq-scheduler. This spec
# reads the file the way the worker does.
RSpec.describe 'config/sidekiq.yml' do # rubocop:disable RSpec/DescribeClass
  let(:config) do
    YAML.safe_load(ERB.new(Rails.root.join('config/sidekiq.yml').read).result, permitted_classes: [Symbol])
  end

  it 'schedules the dispatcher every minute where sidekiq-scheduler looks for it' do
    entry = config.dig(:scheduler, :schedule, 'dispatch_deliveries')

    expect(entry).to include('cron' => '0 * * * * *', 'queue' => 'default')
    expect(entry['class'].constantize).to eq(DispatchDeliveriesJob)
  end

  it 'weights the delivery queue above the default queue' do
    expect(config[:queues]).to eq([['deliveries', 5], ['default', 1]])
  end
end
