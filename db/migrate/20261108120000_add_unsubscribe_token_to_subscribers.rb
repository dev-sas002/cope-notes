# frozen_string_literal: true

class AddUnsubscribeTokenToSubscribers < ActiveRecord::Migration[8.1]
  def up
    add_column :subscribers, :unsubscribe_token, :string, limit: 32

    # Existing subscribers need a token before the column can be NOT NULL.
    # gen_random_uuid() is built into PostgreSQL 13+; the hyphens are dropped
    # so backfilled tokens are URL-safe hex like the ones the model generates.
    execute "UPDATE subscribers SET unsubscribe_token = replace(gen_random_uuid()::text, '-', '')"

    change_column_null :subscribers, :unsubscribe_token, false
    add_index :subscribers, :unsubscribe_token, unique: true
  end

  def down
    remove_index :subscribers, :unsubscribe_token
    remove_column :subscribers, :unsubscribe_token
  end
end
