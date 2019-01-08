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

ActiveRecord::Schema.define(version: 2019_01_08_214424) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "area_details", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "areas_id"
    t.string "name"
    t.string "state"
    t.string "country"
    t.string "language"
    t.index ["areas_id"], name: "index_area_details_on_areas_id"
  end

  create_table "areas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "initial_latitude"
    t.float "final_latitude"
    t.float "initial_longitude"
    t.float "final_longitude"
    t.boolean "es", default: false
    t.boolean "en", default: false
  end

  create_table "audios", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "import_points", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "imports_id"
    t.string "wikipedia_id"
    t.string "wikibase_id"
    t.string "title"
    t.float "latitude"
    t.float "longitude"
    t.index ["imports_id"], name: "index_import_points_on_imports_id"
  end

  create_table "import_text_contents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "import_points_id"
    t.string "title"
    t.string "content"
    t.index ["import_points_id"], name: "index_import_text_contents_on_import_points_id"
  end

  create_table "import_thematic_points", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "import_points_id"
    t.string "wikibase_id"
    t.string "name"
    t.index ["import_points_id"], name: "index_import_thematic_points_on_import_points_id"
  end

  create_table "imports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.float "initial_latitude"
    t.float "final_latitude"
    t.float "initial_longitude"
    t.float "final_longitude"
    t.string "language"
  end

  create_table "operational_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source"
    t.string "event"
    t.string "comment"
  end

  create_table "photos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "point_details", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "points_id"
    t.string "name"
    t.string "local_name"
    t.string "language"
    t.index ["points_id"], name: "index_point_details_on_points_id"
  end

  create_table "points", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "areas_id"
    t.float "latitude"
    t.float "longitude"
    t.integer "likes"
    t.boolean "es"
    t.boolean "en"
    t.index ["areas_id"], name: "index_points_on_areas_id"
  end

  create_table "texts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "thematics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
