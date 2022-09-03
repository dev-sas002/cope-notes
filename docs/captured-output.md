# Captured output

Everything on this page was produced by the stack in `docker-compose.yml` on
2026-09-23, against the seed data in `db/seeds.rb`. Nothing here is illustrative
or reconstructed. The host ports this checkout was tested on are `8191` for the
API and `8192` for Postgres.

## 1. One command, four containers

```console
$ docker compose up --build
cope-notes-db-1	Up 5 minutes (healthy)
cope-notes-redis-1	Up 5 minutes (healthy)
cope-notes-web-1	Up About a minute (healthy)
cope-notes-worker-1	Up About a minute (healthy)
```

The web container owns the schema; the worker waits for it to report healthy and
only then starts the Sidekiq process that carries the schedule.

```console
==> rails db:prepare
== 20220829141020 CreateSubscribers: migrated (0.0077s) =======================
== 20220829142440 CreateMessages: migrated (0.0046s) ==========================
== 20220829143452 CreateSubscriberEmails: migrated (0.0077s) ==================
== 20220830095535 AddUniqueConstraintToSubscriberEmail: migrated (0.0022s) ====
== 20260923090000 AddDeliveryTrackingAndIndexes: migrated (0.0258s) ===========
==> rails db:seed
Seeded: 10 notes, 4 subscribers (3 active)
* Listening on http://0.0.0.0:3000
```

## 2. The pipeline running

The scheduler fires `DispatchDeliveriesJob` once a minute. It enqueues one
`DeliverNoteJob` per due subscriber, and those run in parallel across the Sidekiq
thread pool - three subscribers, three threads, three sends inside 320 ms.

```console
$ docker compose logs worker
2026-09-23T12:24:00.637Z pid=1 tid=dm1 class=DeliverNoteJob jid=ab1c789c77ce557b5642ac1e INFO:   Rendered message_mailer/new_message_email.html.erb within layouts/mailer (Duration: 0.1ms | Allocations: 28)
2026-09-23T12:24:00.639Z pid=1 tid=dm1 class=DeliverNoteJob jid=ab1c789c77ce557b5642ac1e INFO:   Rendered layout layouts/mailer.html.erb (Duration: 9.9ms | Allocations: 13529)
2026-09-23T12:24:00.639Z pid=1 tid=dm1 class=DeliverNoteJob jid=ab1c789c77ce557b5642ac1e INFO:   Rendered message_mailer/new_message_email.text.erb within layouts/mailer (Duration: 0.1ms | Allocations: 40)
2026-09-23T12:24:00.639Z pid=1 tid=dm1 class=DeliverNoteJob jid=ab1c789c77ce557b5642ac1e INFO:   Rendered layout layouts/mailer.text.erb (Duration: 0.2ms | Allocations: 132)
2026-09-23T12:24:00.689Z pid=1 tid=dkx class=DeliverNoteJob jid=1b7bd351b5561da7b7a25fdd INFO: Delivered mail 6ab3c4e09be9b_144c018865@84a333afe935.mail (56.4ms)
2026-09-23T12:24:00.691Z pid=1 tid=dlh class=DeliverNoteJob jid=0c0352f169d978b96a2d4b2b INFO: Delivered mail 6ab3c4e09cd47_144d419166@84a333afe935.mail (53.8ms)
2026-09-23T12:24:00.691Z pid=1 tid=dm1 class=DeliverNoteJob jid=ab1c789c77ce557b5642ac1e INFO: Delivered mail 6ab3c4e09cc13_144e81908b@84a333afe935.mail (49.8ms)
2026-09-23T12:24:00.697Z pid=1 tid=dlh class=DeliverNoteJob jid=0c0352f169d978b96a2d4b2b INFO: Performed DeliverNoteJob (Job ID: db9cf149-9082-440a-9c31-fe7691424804) from Sidekiq(deliveries) in 316.05ms
2026-09-23T12:24:00.697Z pid=1 tid=dkx class=DeliverNoteJob jid=1b7bd351b5561da7b7a25fdd INFO: Performed DeliverNoteJob (Job ID: d9d2cbd7-848e-4ba8-ae11-c537d323134f) from Sidekiq(deliveries) in 316.68ms
2026-09-23T12:24:00.697Z pid=1 tid=dm1 class=DeliverNoteJob jid=ab1c789c77ce557b5642ac1e INFO: Performed DeliverNoteJob (Job ID: f926a81f-94c8-4c45-8524-875e763b3b64) from Sidekiq(deliveries) in 315.64ms
2026-09-23T12:24:00.697Z pid=1 tid=dm1 class=DeliverNoteJob jid=ab1c789c77ce557b5642ac1e elapsed=0.32 INFO: done
2026-09-23T12:24:00.698Z pid=1 tid=dlh class=DeliverNoteJob jid=0c0352f169d978b96a2d4b2b elapsed=0.321 INFO: done
2026-09-23T12:24:00.698Z pid=1 tid=dkx class=DeliverNoteJob jid=1b7bd351b5561da7b7a25fdd elapsed=0.323 INFO: done
2026-09-23T12:25:00.283Z pid=1 tid=cz9 INFO: queueing DispatchDeliveriesJob (dispatch_deliveries)
2026-09-23T12:25:00.296Z pid=1 tid=ejx class=DispatchDeliveriesJob jid=7cc5346f47292bd336e381b2 INFO: start
2026-09-23T12:25:00.297Z pid=1 tid=cz9 INFO: Enqueued DispatchDeliveriesJob (Job ID: 6ac05c66-aa52-4e70-acf6-cb423750ec7c) to Sidekiq(default)
2026-09-23T12:25:00.318Z pid=1 tid=ejx class=DispatchDeliveriesJob jid=7cc5346f47292bd336e381b2 INFO: Performing DispatchDeliveriesJob (Job ID: 6ac05c66-aa52-4e70-acf6-cb423750ec7c) from Sidekiq(default) enqueued at 2026-09-23T12:25:00Z
2026-09-23T12:25:00.342Z pid=1 tid=ejx class=DispatchDeliveriesJob jid=7cc5346f47292bd336e381b2 INFO: [deliveries] dispatched 0 subscriber(s)
2026-09-23T12:25:00.342Z pid=1 tid=ejx class=DispatchDeliveriesJob jid=7cc5346f47292bd336e381b2 INFO: Performed DispatchDeliveriesJob (Job ID: 6ac05c66-aa52-4e70-acf6-cb423750ec7c) from Sidekiq(default) in 23.81ms
2026-09-23T12:25:00.343Z pid=1 tid=ejx class=DispatchDeliveriesJob jid=7cc5346f47292bd336e381b2 elapsed=0.046 INFO: done
```

The last line is the interesting one: the tick a minute later found nobody due,
because every active subscriber had already been sent a note inside the delivery
interval.

## 3. A note actually being delivered

![The mail viewer showing a delivered note](screenshots/delivered-note.png)

Mail sent in development is captured by letter_opener and served at
`/letter_opener`. The note above is a real send by the Sidekiq worker, chosen at
random from the notes that subscriber had not yet received.

![The Sidekiq worker, its two queues and its thread pool](screenshots/sidekiq-dashboard.png)

One process, ten threads, subscribed to `deliveries` and `default`. **If this
process is not running, nothing is ever emailed** - the schedule lives here, not
in the web process.

## 4. Screening a note as it is written

Note text is screened before it is stored. With no `ANTHROPIC_API_KEY` set - as
here - the offline keyword reviewer answers, and the API still returns `201`
with the verdict recorded on the note.

A note that is fine:

```console
$ curl -s -X POST http://localhost:8191/api/v1/messages -H 'Content-Type: application/json' \
       -d '{"message":{"text":"You are allowed to rest before you are finished."}}'
HTTP/1.1 201
{
    "id": 11,
    "text": "You are allowed to rest before you are finished.",
    "review_status": "approved",
    "deliveries_count": 0,
    "subscribers": []
}
```

A note that is unkind rather than dangerous is **flagged**: still deliverable,
but an editor should see it.

```console
$ curl -s -X POST http://localhost:8191/api/v1/messages -H 'Content-Type: application/json' \
       -d '{"message":{"text":"Just get over it, others have it worse."}}'
HTTP/1.1 201
{
    "id": 12,
    "text": "Just get over it, others have it worse.",
    "review_status": "flagged",
    "deliveries_count": 0,
    "subscribers": []
}
```

A note that gives medication advice is **rejected**, and the delivery path will
never select it.

```console
$ curl -s -X POST http://localhost:8191/api/v1/messages -H 'Content-Type: application/json' \
       -d '{"message":{"text":"If it is not working, stop taking your medication for a week."}}'
HTTP/1.1 201
{
    "id": 13,
    "text": "If it is not working, stop taking your medication for a week.",
    "review_status": "rejected",
    "deliveries_count": 0,
    "subscribers": []
}
```

Which is how an editor finds their queue:

```console
$ curl -s http://localhost:8191/api/v1/messages?review_status=flagged
[
    {
        "id": 12,
        "text": "Just get over it, others have it worse.",
        "review_status": "flagged",
        "deliveries_count": 0,
        "subscribers": []
    }
]
```

## 5. The rest of the API

Addresses are normalised on the way in, so `Robin@Example.COM` and
`robin@example.com` cannot both subscribe:

```console
$ curl -s -X POST http://localhost:8191/api/v1/subscribers -H 'Content-Type: application/json' \
       -d '{"subscriber":{"name":"Robin","email":"Robin@Example.COM"}}'
HTTP/1.1 201
{
    "id": 5,
    "name": "Robin",
    "email": "robin@example.com",
    "is_active": true,
    "last_delivered_at": null,
    "messages": []
}
```

```console
$ curl -s -X POST http://localhost:8191/api/v1/subscribers -H 'Content-Type: application/json' \
       -d '{"subscriber":{"name":"","email":"nope"}}'
HTTP/1.1 422
{
    "name": [
        "can't be blank"
    ],
    "email": [
        "is invalid"
    ]
}
```

## 6. Dispatching twice does not send twice

```console
$ docker compose exec web bundle exec rails deliveries:tick
Enqueued 4 delivery job(s). They run in the Sidekiq process.

$ docker compose exec web bundle exec rails deliveries:tick     # straight away, again
Enqueued 0 delivery job(s). They run in the Sidekiq process.
```

The first tick found four subscribers due and enqueued four jobs. The second,
seconds later, found none - the interval had already been consumed. If two ticks
ever do overlap, `Subscriber.claim_delivery_slot` is a single conditional
`UPDATE`, so only one of them is told to send.

## 7. Operational snapshot

```console
$ curl -s http://localhost:8191/api/v1/deliveries/stats
{
    "generated_at": "2026-09-23T12:26:23.152Z",
    "channel": "email",
    "selection_strategy": "random_unsent",
    "interval_minutes": 1,
    "subscribers": {
        "total": 5,
        "active": 4,
        "due_now": 0,
        "exhausted": 0
    },
    "notes": {
        "total": 13,
        "deliverable": 12,
        "by_review_status": {
            "flagged": 1,
            "approved": 11,
            "rejected": 1
        }
    },
    "deliveries": {
        "total": 7,
        "by_status": {
            "delivered": 7
        },
        "last_24h": 7
    }
}
```

Every figure is a database aggregate. The endpoint costs the same with ten
deliveries or ten million.

## 8. The scalability measurement

`rails "deliveries:benchmark[10000,200,60]"` against the same Postgres container:
10,000 subscribers, 200 notes, 600,000 existing delivery rows. The absolute
milliseconds were measured on a laptop that was running other containers at the
time - the ratios and the allocation counts (which are deterministic) are the
signal.

```console
seeding 10000 subscribers, 200 notes, 600000 delivery rows
seeded

--- one tick's work for a page of 1000 subscribers ---
  previous: whole-pool hash + includes(:messages) + set subtraction   1949.8 ms     1,400,601 objects
  current:  keyset page of ids + one anti-join query per subscriber   1234.9 ms       391,484 objects

--- the two halves of that, separately ---
  previous: Subscriber.active.includes(:messages), one page        1438.9 ms     1,330,951 objects
  current:  Subscriber.due, one keyset page of ids                    4.1 ms         1,404 objects

--- extrapolated to 10000 subscribers ---
  selection: 0.91 ms per subscriber, 9.1 s of database time per tick
  sending:   at 150 ms per SMTP round trip, one thread needs 1500 s per tick; 25 Sidekiq threads need 60 s

--- query plan for the selection query ---
  Limit  (cost=20.88..20.89 rows=1 width=587) (actual time=0.135..0.136 rows=1 loops=1)
    Buffers: shared hit=9
    ->  Sort  (cost=20.88..21.23 rows=140 width=587) (actual time=0.134..0.135 rows=1 loops=1)
          Sort Key: (random())
          Sort Method: top-N heapsort  Memory: 25kB
          Buffers: shared hit=9
          ->  Hash Right Anti Join  (cost=10.43..20.18 rows=140 width=587) (actual time=0.094..0.109 rows=140 loops=1)
                Hash Cond: (se.message_id = messages.id)
                Buffers: shared hit=9
                ->  Index Scan using index_subscriber_emails_on_subscriber_id on subscriber_emails se  (cost=0.42..9.47 rows=60 width=8) (actual time=0.015..0.020 rows=60 loops=1)
                      Index Cond: (subscriber_id = 1)
                      Buffers: shared hit=4
                ->  Hash  (cost=7.50..7.50 rows=200 width=579) (actual time=0.048..0.048 rows=200 loops=1)
                      Buckets: 1024  Batches: 1  Memory Usage: 27kB
                      Buffers: shared hit=5
                      ->  Seq Scan on messages  (cost=0.00..7.50 rows=200 width=579) (actual time=0.007..0.028 rows=200 loops=1)
                            Filter: ((review_status)::text <> 'rejected'::text)
                            Buffers: shared hit=5
  Planning:
    Buffers: shared hit=4
  Planning Time: 0.131 ms
  Execution Time: 0.173 ms
```

## 9. The test suite

```console
$ docker compose run --rm -e RAILS_ENV=test web bundle exec rspec
...............................................................................................................................................
Finished in 2.64 seconds (files took 1.13 seconds to load)
143 examples, 0 failures
```
