# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20151016142136) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "article_marks", force: :cascade do |t|
    t.integer "note"
    t.integer "article_id"
    t.integer "user_id"
  end

  add_index "article_marks", ["user_id"], name: "index_article_marks_on_user_id", using: :btree

  create_table "keyword_marks", force: :cascade do |t|
    t.integer  "note"
    t.integer  "user_id"
    t.integer  "keyword_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "keyword_marks", ["keyword_id"], name: "index_keyword_marks_on_keyword_id", using: :btree
  add_index "keyword_marks", ["user_id"], name: "index_keyword_marks_on_user_id", using: :btree

  create_table "keywords", force: :cascade do |t|
    t.string   "keyword"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "linked_marks", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "linked_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "linked_marks", ["linked_id"], name: "index_linked_marks_on_linked_id", using: :btree
  add_index "linked_marks", ["user_id"], name: "index_linked_marks_on_user_id", using: :btree

  create_table "linkeds", force: :cascade do |t|
    t.integer  "keyword_id"
    t.integer  "linked_keyword_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "linkeds", ["keyword_id"], name: "index_linkeds_on_keyword_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "name"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  add_foreign_key "article_marks", "users"
  add_foreign_key "keyword_marks", "keywords"
  add_foreign_key "keyword_marks", "users"
  add_foreign_key "linked_marks", "linkeds"
  add_foreign_key "linked_marks", "users"
  add_foreign_key "linkeds", "keywords"
end
