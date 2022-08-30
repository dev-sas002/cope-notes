class CreateSubscriberEmails < ActiveRecord::Migration[6.1]
  def change
    create_table :subscriber_emails do |t|
      t.belongs_to :subscriber
      t.belongs_to :message

      t.timestamps
    end
  end
end
