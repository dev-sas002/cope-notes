# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2026_09_23_090000) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "messages", force: :cascade do |t|
    t.string "text", limit: 500, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "review_status", default: "approved", null: false
    t.string "review_notes", limit: 255
    t.datetime "reviewed_at"
    t.integer "deliveries_count", default: 0, null: false
    t.index ["review_status"], name: "index_messages_needing_review", where: "((review_status)::text <> 'approved'::text)"
  end

  create_table "subscriber_emails", force: :cascade do |t|
    t.bigint "subscriber_id"
    t.bigint "message_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "status", default: "claimed", null: false
    t.string "channel", default: "email", null: false
    t.datetime "delivered_at"
    t.string "provider_reference", limit: 255
    t.string "failure_reason", limit: 255
    t.index ["message_id"], name: "index_subscriber_emails_on_message_id"
    t.index ["status"], name: "index_subscriber_emails_needing_attention", where: "((status)::text <> 'delivered'::text)"
    t.index ["subscriber_id", "message_id"], name: "index_subscriber_emails_on_subscriber_id_and_message_id", unique: true
    t.index ["subscriber_id"], name: "index_subscriber_emails_on_subscriber_id"
  end

  create_table "subscribers", force: :cascade do |t|
    t.string "email", limit: 50, null: false
    t.string "name", limit: 50, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "last_delivered_at"
    t.index ["email"], name: "index_subscribers_on_email", unique: true
    t.index ["last_delivered_at", "id"], name: "index_subscribers_due_for_delivery", where: "is_active"
  end

end
