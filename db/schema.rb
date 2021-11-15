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

ActiveRecord::Schema.define(version: 2021_11_15_021842) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "line_1", null: false
    t.string "line_2"
    t.string "city", null: false
    t.string "state", null: false
    t.integer "zip", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "property_id"
    t.index ["property_id"], name: "index_addresses_on_property_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "guest_id", null: false
    t.datetime "start_date", null: false
    t.datetime "end_date", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["guest_id"], name: "index_bookings_on_guest_id"
    t.index ["property_id"], name: "index_bookings_on_property_id"
  end

  create_table "properties", force: :cascade do |t|
    t.integer "beds", null: false
    t.integer "baths", null: false
    t.integer "square_feet", null: false
    t.boolean "smoking", null: false
    t.boolean "pets", null: false
    t.decimal "nightly_rate", precision: 10, scale: 2, null: false
    t.text "description", null: false
    t.bigint "manager_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "title"
    t.string "image_directory"
    t.index ["manager_id"], name: "index_properties_on_manager_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.bigint "manager_id", null: false
    t.bigint "guest_id", null: false
    t.integer "rating", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "type"
    t.index ["guest_id"], name: "index_ratings_on_guest_id"
    t.index ["manager_id"], name: "index_ratings_on_manager_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "session_token"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "username", null: false
    t.string "image_url"
  end

  add_foreign_key "addresses", "properties"
  add_foreign_key "bookings", "properties"
  add_foreign_key "bookings", "users", column: "guest_id"
  add_foreign_key "properties", "users", column: "manager_id"
  add_foreign_key "ratings", "users", column: "guest_id"
  add_foreign_key "ratings", "users", column: "manager_id"
end
