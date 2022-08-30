# frozen_string_literal: true

module Deliveries
  # Measures the two things that decide whether this pipeline survives growth:
  # how expensive it is to choose a note for one subscriber, and how expensive
  # it is to work out who is due.
  #
  # It compares the current implementation against the approach it replaced -
  # load every note into a hash, then load every subscriber with every delivery
  # row attached - so the README can quote measurements rather than opinions.
  #
  # Driven by `rails "deliveries:benchmark[subscribers,notes,deliveries_each]"`.
  class Benchmark
    # Typical wall-clock cost of one SMTP round trip, and the size of a
    # modest Sidekiq fleet - used to extrapolate the send half of a tick.
    SMTP_SECONDS = 0.15
    THREADS = 25

    def initialize(subscribers:, notes:, deliveries_each:)
      @subscribers = subscribers
      @notes = notes
      @deliveries_each = [deliveries_each, notes].min
    end

    # Bulk-inserts the fixture data in SQL. Doing this through Active Record
    # would itself take minutes at these row counts.
    def seed!
      say "seeding #{subscribers} subscribers, #{notes} notes, " \
          "#{subscribers * deliveries_each} delivery rows"
      truncate!
      insert_notes!
      insert_subscribers!
      insert_deliveries!
      connection.execute('ANALYZE messages; ANALYZE subscribers; ANALYZE subscriber_emails')
      say 'seeded'
    end

    def report
      page_size = [Deliveries.batch_size, subscribers].min
      say "\n--- one tick's work for a page of #{page_size} subscribers ---"
      measure('previous: whole-pool hash + includes(:messages) + set subtraction') { previous_tick(page_size) }
      measure('current:  keyset page of ids + one anti-join query per subscriber') { current_tick(page_size) }

      say "\n--- the two halves of that, separately ---"
      measure('previous: Subscriber.active.includes(:messages), one page') do
        Subscriber.active.includes(:messages).limit(page_size).to_a
      end
      measure('current:  Subscriber.due, one keyset page of ids') { due_page(page_size) }

      report_tick(page_size)
      report_plan
    end

    # Exactly what the job used to do, for one page of subscribers.
    def previous_tick(page_size)
      pool = Message.all.index_by(&:id)
      Subscriber.active.includes(:messages).limit(page_size).each do |subscriber|
        available = pool.keys - subscriber.messages.map(&:id)
        pool[available.sample] unless available.empty?
      end
    end

    def current_tick(page_size)
      selector = Selectors::RandomUnsent.new
      Subscriber.where(id: due_page(page_size)).find_each { |subscriber| selector.call(subscriber) }
    end

    def due_page(page_size, cursor = 0)
      Subscriber.due.where('subscribers.id > ?', cursor).order(:id).limit(page_size).pluck(:id)
    end

    private

    attr_reader :subscribers, :notes, :deliveries_each

    def report_tick(page_size)
      say "\n--- extrapolated to #{subscribers} subscribers ---"
      report_selection_cost(seconds_per_subscriber(page_size))
      report_send_cost
    end

    # Mean wall-clock cost of choosing a note, measured over one keyset page.
    def seconds_per_subscriber(page_size)
      selector = Selectors::RandomUnsent.new
      ids = due_page(page_size)
      time { Subscriber.where(id: ids).find_each { |subscriber| selector.call(subscriber) } } / ids.size
    end

    def report_selection_cost(each)
      say format('  selection: %<each>.2f ms per subscriber, %<total>.1f s of database time per tick',
                 each: each * 1_000, total: each * subscribers)
    end

    def report_send_cost
      serial = subscribers * SMTP_SECONDS
      say format('  sending:   at %<smtp>d ms per SMTP round trip, one thread needs %<serial>.0f s per tick; ' \
                 '%<threads>d Sidekiq threads need %<parallel>.0f s',
                 smtp: SMTP_SECONDS * 1_000, serial: serial, threads: THREADS, parallel: serial / THREADS)
    end

    def report_plan
      say "\n--- query plan for the selection query ---"
      subscriber_id = Subscriber.order(:id).limit(1).pick(:id)
      sql = Message.deliverable.unsent_to(subscriber_id).order(Arel.sql('RANDOM()')).limit(1).to_sql
      connection.execute("EXPLAIN (ANALYZE, BUFFERS) #{sql}").each { |row| say "  #{row['QUERY PLAN']}" }
    end

    def measure(label, &block)
      GC.start
      objects_before = GC.stat[:total_allocated_objects]
      elapsed = time(&block)
      allocated = GC.stat[:total_allocated_objects] - objects_before
      say format('  %<label>-62s %<elapsed>8.1f ms  %<allocated>12s objects',
                 label: label, elapsed: elapsed * 1_000, allocated: allocated.to_s(:delimited))
    end

    def time(&block)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      block.call
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    end

    def truncate!
      connection.execute('TRUNCATE subscriber_emails, subscribers, messages RESTART IDENTITY CASCADE')
    end

    def insert_notes!
      connection.execute(<<~SQL.squish)
        INSERT INTO messages (text, review_status, deliveries_count, created_at, updated_at)
        SELECT 'benchmark note ' || i, 'approved', 0, NOW(), NOW()
        FROM generate_series(1, #{notes}) AS i
      SQL
    end

    def insert_subscribers!
      connection.execute(<<~SQL.squish)
        INSERT INTO subscribers (email, name, is_active, last_delivered_at, created_at, updated_at)
        SELECT 'bench' || i || '@example.com', 'Bench ' || i, TRUE, NULL, NOW(), NOW()
        FROM generate_series(1, #{subscribers}) AS i
      SQL
    end

    # Each subscriber gets the first `deliveries_each` notes, which is the worst
    # realistic case for the anti-join: a dense, contiguous block of rows.
    def insert_deliveries!
      connection.execute(<<~SQL.squish)
        INSERT INTO subscriber_emails
          (subscriber_id, message_id, status, channel, delivered_at, created_at, updated_at)
        SELECT s.id, m.id, 'delivered', 'email', NOW(), NOW(), NOW()
        FROM subscribers s
        JOIN messages m ON m.id <= #{deliveries_each}
      SQL
      connection.execute(<<~SQL.squish)
        UPDATE messages
        SET deliveries_count = (
          SELECT COUNT(*) FROM subscriber_emails WHERE subscriber_emails.message_id = messages.id
        )
      SQL
    end

    def connection
      ActiveRecord::Base.connection
    end

    def say(message)
      puts message
    end
  end
end
