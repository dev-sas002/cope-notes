class CreateSubscribers < ActiveRecord::Migration[6.1]
  def change
    create_table :subscribers do |t|
      t.string :email, limit: 50, null: false
      t.string :name, limit: 50, null: false
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :subscribers, :email, unique: true
  end
end
