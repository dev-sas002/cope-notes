# frozen_string_literal: true

namespace :deliveries do
  desc 'Run the dispatcher once, now, without waiting for the cron'
  task tick: :environment do
    enqueued = Deliveries::Dispatcher.call
    puts "Enqueued #{enqueued} delivery job(s). They run in the Sidekiq process."
  end

  desc 'Send one subscriber their next note synchronously (SUBSCRIBER_ID=1)'
  task deliver: :environment do
    subscriber = Subscriber.find(ENV.fetch('SUBSCRIBER_ID'))
    result = Deliveries::SendNextNote.call(subscriber)
    puts "#{subscriber.email}: #{result}"
  end

  desc 'Print the same figures as GET /api/v1/deliveries/stats'
  task stats: :environment do
    puts JSON.pretty_generate(Deliveries::Stats.call)
  end

  # Reproduces the scalability numbers quoted in the README. It writes a lot of
  # rows, so it refuses to run outside development and test.
  #
  #   bundle exec rails "deliveries:benchmark[10000,200,60]"
  #
  desc 'Benchmark note selection and dispatch at scale [subscribers,notes,deliveries_each]'
  task :benchmark, %i[subscribers notes deliveries_each] => :environment do |_task, args|
    raise 'refusing to run the benchmark outside development/test' if Rails.env.production?

    bench = Deliveries::Benchmark.new(
      subscribers: Integer(args.fetch(:subscribers, 10_000)),
      notes: Integer(args.fetch(:notes, 200)),
      deliveries_each: Integer(args.fetch(:deliveries_each, 60))
    )
    bench.seed!
    bench.report
  end
end
