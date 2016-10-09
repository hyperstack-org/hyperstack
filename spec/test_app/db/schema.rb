# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160731182106) do

  create_table "child_models", force: :cascade do |t|
    t.string  "child_attribute"
    t.integer "test_model_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text     "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "todo_id"
    t.integer  "author_id"
  end

  create_table "test_models", force: :cascade do |t|
    t.string   "test_attribute"
    t.boolean  "completed"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "todos", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.boolean  "completed",     default: false, null: false
    t.integer  "created_by_id"
    t.integer  "owner_id"
  end

  create_table "users", force: :cascade do |t|
    t.string  "role"
    t.string  "name"
    t.integer "manager_id"
  end

end
