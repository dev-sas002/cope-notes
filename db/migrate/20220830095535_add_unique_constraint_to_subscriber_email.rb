# frozen_string_literal: true

class AddUniqueConstraintToSubscriberEmail < ActiveRecord::Migration[6.1]
  def change
    add_index :subscriber_emails, %i[subscriber_id message_id], unique: true
  end
end
