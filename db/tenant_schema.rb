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

ActiveRecord::Schema[8.1].define(version: 2025_11_29_000001) do
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
    t.datetime "updated_at", null: false
    t.string "username"
  end
end
