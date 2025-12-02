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

ActiveRecord::Schema[8.1].define(version: 2025_12_02_045723) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "channel_users", force: :cascade do |t|
    t.integer "channel_id", null: false
    t.datetime "created_at", null: false
    t.string "modes"
    t.string "nickname", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id", "nickname"], name: "index_channel_users_on_channel_id_and_nickname", unique: true
    t.index ["channel_id"], name: "index_channel_users_on_channel_id"
  end

  create_table "channels", force: :cascade do |t|
    t.boolean "auto_join", default: false, null: false
    t.datetime "created_at", null: false
    t.boolean "joined", default: false, null: false
    t.integer "last_read_message_id"
    t.string "name", null: false
    t.integer "server_id", null: false
    t.string "topic"
    t.datetime "updated_at", null: false
    t.index ["server_id", "name"], name: "index_channels_on_server_id_and_name", unique: true
    t.index ["server_id"], name: "index_channels_on_server_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_message_at"
    t.integer "last_read_message_id"
    t.integer "server_id", null: false
    t.string "target_nick", null: false
    t.datetime "updated_at", null: false
    t.index ["server_id", "target_nick"], name: "index_conversations_on_server_id_and_target_nick", unique: true
    t.index ["server_id"], name: "index_conversations_on_server_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "channel_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.string "message_type", default: "privmsg", null: false
    t.string "sender", null: false
    t.integer "server_id", null: false
    t.string "target"
    t.datetime "updated_at", null: false
    t.index ["channel_id"], name: "index_messages_on_channel_id"
    t.index ["server_id"], name: "index_messages_on_server_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "message_id", null: false
    t.datetime "read_at"
    t.string "reason", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_notifications_on_message_id"
  end

  create_table "servers", force: :cascade do |t|
    t.string "address", null: false
    t.string "auth_method", default: "none"
    t.string "auth_password"
    t.datetime "connected_at"
    t.datetime "created_at", null: false
    t.string "nickname", null: false
    t.integer "port", default: 6697, null: false
    t.integer "process_pid"
    t.string "realname"
    t.boolean "ssl", default: true, null: false
    t.boolean "ssl_verify", default: true
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "username"
    t.index ["user_id", "address", "port"], name: "index_servers_on_user_id_and_address_and_port", unique: true
    t.index ["user_id"], name: "index_servers_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "channel_users", "channels"
  add_foreign_key "channels", "servers"
  add_foreign_key "conversations", "servers"
  add_foreign_key "messages", "channels", on_delete: :nullify
  add_foreign_key "messages", "servers"
  add_foreign_key "notifications", "messages"
  add_foreign_key "servers", "users"
  add_foreign_key "sessions", "users"
end
