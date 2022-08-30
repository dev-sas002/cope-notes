class AddUniqueConstraintToSubscriberEmail < ActiveRecord::Migration[6.1]
  def change
    add_index :subscriber_emails, [:subscriber_id, :message_id], unique: true
  end
end
