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

ActiveRecord::Schema.define(version: 2021_02_28_200459) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "street"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bones", force: :cascade do |t|
    t.integer "dog_id"
  end

  create_table "child_models", force: :cascade do |t|
    t.string "child_attribute"
    t.bigint "test_model_id"
    t.index ["test_model_id"], name: "index_child_models_on_test_model_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "todo_id"
    t.bigint "author_id"
    t.integer "user_id"
    t.integer "todo_item_id"
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["todo_id"], name: "index_comments_on_todo_id"
  end

  create_table "hyperstack_connections", force: :cascade do |t|
    t.string "channel"
    t.string "session"
    t.datetime "created_at"
    t.datetime "expires_at"
    t.datetime "refresh_at"
  end

  create_table "hyperstack_queued_messages", force: :cascade do |t|
    t.text "data"
    t.integer "connection_id"
  end

  create_table "pets", force: :cascade do |t|
    t.integer "owner_id"
  end

  create_table "scratching_posts", force: :cascade do |t|
    t.integer "cat_id"
  end

  create_table "test_models", force: :cascade do |t|
    t.string "test_attribute"
    t.boolean "completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "todo_items", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.boolean "complete"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.integer "comment_id"
  end

  create_table "todos", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "completed", default: false, null: false
    t.bigint "created_by_id"
    t.bigint "owner_id"
    t.index ["created_by_id"], name: "index_todos_on_created_by_id"
    t.index ["owner_id"], name: "index_todos_on_owner_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "role"
    t.bigint "manager_id"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "address_street"
    t.string "address_city"
    t.string "address_state"
    t.string "address_zip"
    t.integer "address_id"
    t.string "address2_street"
    t.string "address2_city"
    t.string "address2_state"
    t.string "address2_zip"
    t.string "data_string"
    t.integer "data_times"
    t.integer "test_enum"
    t.index ["manager_id"], name: "index_users_on_manager_id"
  end

end
