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

ActiveRecord::Schema[7.2].define(version: 2025_07_24_040648) do
  create_table "completed_sets", force: :cascade do |t|
    t.string "name"
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_completed_sets_on_team_id"
  end

  create_table "drops", force: :cascade do |t|
    t.integer "team_id", null: false
    t.integer "item_id", null: false
    t.string "img_url"
    t.string "owner"
    t.string "reviewed_by"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "submitter"
    t.index ["item_id"], name: "index_drops_on_item_id"
    t.index ["team_id"], name: "index_drops_on_team_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.integer "points"
    t.integer "completed_set_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_set_id"], name: "index_items_on_completed_set_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "completed_sets", "teams"
  add_foreign_key "drops", "items"
  add_foreign_key "drops", "teams"
  add_foreign_key "items", "completed_sets"
end
