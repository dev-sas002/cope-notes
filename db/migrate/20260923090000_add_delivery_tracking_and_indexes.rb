# frozen_string_literal: true

class AddDeliveryTrackingAndIndexes < ActiveRecord::Migration[6.1]
  def up
    add_delivery_tracking
    add_review_tracking
    add_subscriber_scheduling
  end

  def down
    remove_subscriber_scheduling
    remove_review_tracking
    remove_delivery_tracking
  end

  private

  def add_delivery_tracking
    # --- deliveries ---------------------------------------------------------
    # Existing rows were written by the pre-claim code path, which committed the
    # row and the send together, so everything already in the table was sent.
    change_table :subscriber_emails, bulk: true do |t|
      t.string :status, null: false, default: 'delivered'
      t.string :channel, null: false, default: 'email'
      t.datetime :delivered_at
      t.string :provider_reference, limit: 255
      t.string :failure_reason, limit: 255
    end
    change_column_default :subscriber_emails, :status, from: 'delivered', to: 'claimed'

    execute 'UPDATE subscriber_emails SET delivered_at = created_at WHERE delivered_at IS NULL'

    # Only rows that need attention are indexed; delivered rows are the vast
    # majority and are never queried by status.
    add_index :subscriber_emails, :status,
              where: "status <> 'delivered'",
              name: 'index_subscriber_emails_needing_attention'
  end

  def add_review_tracking
    # --- notes --------------------------------------------------------------
    change_table :messages, bulk: true do |t|
      t.string :review_status, null: false, default: 'approved'
      t.string :review_notes, limit: 255
      t.datetime :reviewed_at
      t.integer :deliveries_count, null: false, default: 0
    end

    execute <<~SQL.squish
      UPDATE messages
      SET deliveries_count = (
        SELECT COUNT(*) FROM subscriber_emails WHERE subscriber_emails.message_id = messages.id
      )
    SQL

    add_index :messages, :review_status,
              where: "review_status <> 'approved'",
              name: 'index_messages_needing_review'
  end

  def add_subscriber_scheduling
    # --- subscribers --------------------------------------------------------
    add_column :subscribers, :last_delivered_at, :datetime
    # is_active has had a default since it was created; this closes the NULL hole.
    change_column_null :subscribers, :is_active, false, true

    execute <<~SQL.squish
      UPDATE subscribers
      SET last_delivered_at = (
        SELECT MAX(created_at) FROM subscriber_emails
        WHERE subscriber_emails.subscriber_id = subscribers.id
      )
    SQL

    # Covers Subscriber.due exactly: the partial predicate removes unsubscribed
    # rows from the index entirely, last_delivered_at gives the range scan and
    # the trailing id makes the dispatcher's keyset pagination an index-only walk.
    add_index :subscribers, %i[last_delivered_at id],
              where: 'is_active',
              name: 'index_subscribers_due_for_delivery'
  end

  def remove_subscriber_scheduling
    remove_index :subscribers, name: 'index_subscribers_due_for_delivery'
    change_column_null :subscribers, :is_active, true
    remove_column :subscribers, :last_delivered_at
  end

  def remove_review_tracking
    remove_index :messages, name: 'index_messages_needing_review'
    change_table :messages, bulk: true do |t|
      t.remove :deliveries_count, :reviewed_at, :review_notes, :review_status
    end
  end

  def remove_delivery_tracking
    remove_index :subscriber_emails, name: 'index_subscriber_emails_needing_attention'
    change_table :subscriber_emails, bulk: true do |t|
      t.remove :failure_reason, :provider_reference, :delivered_at, :channel, :status
    end
  end
end
