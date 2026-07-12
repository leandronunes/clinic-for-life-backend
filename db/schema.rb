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

ActiveRecord::Schema[8.1].define(version: 2026_07_12_141953) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "anamneses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "diastolic_pressure"
    t.text "dislocations"
    t.text "fracture"
    t.float "height"
    t.string "hydration"
    t.text "meals"
    t.text "medicines"
    t.text "notes"
    t.text "objectives"
    t.text "orthopedic_notes"
    t.text "pain"
    t.string "sleep"
    t.string "stool"
    t.bigint "student_id", null: false
    t.text "supplements"
    t.float "systolic_pressure"
    t.datetime "updated_at", null: false
    t.string "urine"
    t.float "variable_glycemia"
    t.float "weight"
    t.index ["student_id"], name: "index_anamneses_on_student_id", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.string "justification"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "bioimpedance_imports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "errors_log", default: [], null: false
    t.string "filename", null: false
    t.integer "imported_count", default: 0, null: false
    t.integer "total_rows", default: 0, null: false
    t.bigint "trainer_id"
    t.datetime "updated_at", null: false
    t.index ["trainer_id"], name: "index_bioimpedance_imports_on_trainer_id"
  end

  create_table "bioimpedance_measurements", force: :cascade do |t|
    t.decimal "bmi", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.decimal "fat_percentage", precision: 5, scale: 2
    t.date "measured_on", null: false
    t.decimal "muscle_mass_kg", precision: 6, scale: 2
    t.string "source", default: "InBody", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "visceral_fat", precision: 5, scale: 2
    t.decimal "weight_kg", precision: 6, scale: 2, null: false
    t.index ["student_id", "measured_on"], name: "index_bioimpedance_measurements_on_student_id_and_measured_on", unique: true
    t.index ["student_id"], name: "index_bioimpedance_measurements_on_student_id"
  end

  create_table "biomechanical_assessments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id"], name: "index_biomechanical_assessments_on_student_id"
  end

  create_table "biomechanical_images", force: :cascade do |t|
    t.bigint "biomechanical_assessment_id", null: false
    t.datetime "created_at", null: false
    t.string "image_url", null: false
    t.string "slot", null: false
    t.datetime "updated_at", null: false
    t.index ["biomechanical_assessment_id", "slot"], name: "index_biomechanical_images_on_assessment_and_slot", unique: true
    t.index ["biomechanical_assessment_id"], name: "index_biomechanical_images_on_biomechanical_assessment_id"
  end

  create_table "evolution_photos", force: :cascade do |t|
    t.bigint "bioimpedance_measurement_id"
    t.datetime "created_at", null: false
    t.string "image_url", null: false
    t.bigint "student_id", null: false
    t.date "taken_on", null: false
    t.datetime "updated_at", null: false
    t.index ["bioimpedance_measurement_id"], name: "index_evolution_photos_on_bioimpedance_measurement_id", unique: true
    t.index ["student_id"], name: "index_evolution_photos_on_student_id"
  end

  create_table "exams", force: :cascade do |t|
    t.string "content_type"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "file_url", null: false
    t.string "name", null: false
    t.bigint "size"
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.datetime "uploaded_at", null: false
    t.index ["student_id"], name: "index_exams_on_student_id"
  end

  create_table "exercise_check_ins", force: :cascade do |t|
    t.datetime "completed_at", null: false
    t.datetime "created_at", null: false
    t.bigint "exercise_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "workout_check_in_id", null: false
    t.index ["exercise_id"], name: "index_exercise_check_ins_on_exercise_id"
    t.index ["workout_check_in_id", "exercise_id"], name: "index_exercise_check_ins_on_check_in_and_exercise", unique: true
    t.index ["workout_check_in_id"], name: "index_exercise_check_ins_on_workout_check_in_id"
  end

  create_table "exercises", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "distance_unit"
    t.decimal "distance_value", precision: 6, scale: 2
    t.integer "duration_seconds"
    t.string "heart_rate_bpm"
    t.integer "hr_zone"
    t.string "kind", default: "strength", null: false
    t.decimal "load_kg", precision: 6, scale: 2
    t.string "muscle_group"
    t.string "name", null: false
    t.text "notes"
    t.integer "position", default: 1, null: false
    t.string "reps"
    t.integer "rest_seconds", default: 60, null: false
    t.integer "sets", default: 1, null: false
    t.datetime "updated_at", null: false
    t.string "video_url"
    t.bigint "workout_id", null: false
    t.index ["workout_id"], name: "index_exercises_on_workout_id"
  end

  create_table "external_professionals", force: :cascade do |t|
    t.bigint "anamnesis_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "objective"
    t.string "specialty"
    t.datetime "updated_at", null: false
    t.index ["anamnesis_id"], name: "index_external_professionals_on_anamnesis_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.text "message", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_feedbacks_on_author_id"
    t.index ["student_id", "created_at"], name: "index_feedbacks_on_student_id_and_created_at"
    t.index ["student_id"], name: "index_feedbacks_on_student_id"
  end

  create_table "partners", force: :cascade do |t|
    t.string "category", null: false
    t.string "coupon"
    t.datetime "created_at", null: false
    t.text "description"
    t.text "discount_details"
    t.string "link"
    t.string "logo_url"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_partners_on_category"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth_key", null: false
    t.datetime "created_at", null: false
    t.text "endpoint", null: false
    t.string "p256dh_key", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "structural_assessments", force: :cascade do |t|
    t.boolean "cavus_foot_arch", default: false, null: false
    t.datetime "created_at", null: false
    t.boolean "flat_foot_arch", default: false, null: false
    t.boolean "hip_rotation", default: false, null: false
    t.boolean "hyperkyphosis", default: false, null: false
    t.boolean "hyperlordosis", default: false, null: false
    t.boolean "knee_valgus", default: false, null: false
    t.boolean "knee_varus", default: false, null: false
    t.boolean "limb_length_difference", default: false, null: false
    t.boolean "pelvic_anteversion", default: false, null: false
    t.boolean "pelvic_retroversion", default: false, null: false
    t.boolean "scapular_dyskinesis", default: false, null: false
    t.boolean "scapular_girdle_imbalance", default: false, null: false
    t.boolean "scoliosis", default: false, null: false
    t.boolean "shortening", default: false, null: false
    t.boolean "spine_rotation", default: false, null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id"], name: "index_structural_assessments_on_student_id", unique: true
  end

  create_table "students", force: :cascade do |t|
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "emergency_contact"
    t.string "health_plan"
    t.string "name", null: false
    t.boolean "partner_card_enabled", default: true, null: false
    t.string "phone"
    t.string "sex", default: "other", null: false
    t.string "status", default: "active", null: false
    t.bigint "trainer_id"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_students_on_email", unique: true
    t.index ["status"], name: "index_students_on_status"
    t.index ["trainer_id"], name: "index_students_on_trainer_id"
  end

  create_table "trainers", force: :cascade do |t|
    t.string "avatar_url"
    t.string "cpf"
    t.datetime "created_at", null: false
    t.string "cref"
    t.string "email", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["cpf"], name: "index_trainers_on_cpf", unique: true
    t.index ["cref"], name: "index_trainers_on_cref", unique: true
    t.index ["email"], name: "index_trainers_on_email", unique: true
    t.index ["status"], name: "index_trainers_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "last_login_at"
    t.boolean "mfa_enabled", default: false, null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role", default: "student", null: false
    t.bigint "student_id"
    t.datetime "terms_accepted_at"
    t.bigint "trainer_id"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["student_id"], name: "index_users_on_student_id"
    t.index ["trainer_id"], name: "index_users_on_trainer_id"
  end

  create_table "workout_check_ins", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "status", default: "in_progress", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "workout_id", null: false
    t.index ["student_id", "created_at"], name: "index_workout_check_ins_on_student_id_and_created_at"
    t.index ["student_id"], name: "index_workout_check_ins_on_student_id"
    t.index ["workout_id"], name: "index_workout_check_ins_on_workout_id"
    t.index ["workout_id"], name: "index_workout_check_ins_on_workout_in_progress", unique: true, where: "((status)::text = 'in_progress'::text)"
  end

  create_table "workouts", force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.string "focus"
    t.integer "position", default: 1, null: false
    t.string "status", default: "active", null: false
    t.bigint "student_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id", "position"], name: "index_workouts_on_student_active_position", unique: true, where: "((status)::text = 'active'::text)"
    t.index ["student_id", "position"], name: "index_workouts_on_student_archived_position", unique: true, where: "((status)::text = 'archived'::text)"
    t.index ["student_id", "status"], name: "index_workouts_on_student_id_and_status"
    t.index ["student_id"], name: "index_workouts_on_student_id"
  end

  add_foreign_key "anamneses", "students"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "bioimpedance_imports", "trainers"
  add_foreign_key "bioimpedance_measurements", "students"
  add_foreign_key "biomechanical_assessments", "students"
  add_foreign_key "biomechanical_images", "biomechanical_assessments"
  add_foreign_key "evolution_photos", "bioimpedance_measurements"
  add_foreign_key "evolution_photos", "students"
  add_foreign_key "exams", "students"
  add_foreign_key "exercise_check_ins", "exercises"
  add_foreign_key "exercise_check_ins", "workout_check_ins"
  add_foreign_key "exercises", "workouts"
  add_foreign_key "external_professionals", "anamneses", column: "anamnesis_id"
  add_foreign_key "feedbacks", "students"
  add_foreign_key "feedbacks", "users", column: "author_id"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "structural_assessments", "students"
  add_foreign_key "students", "trainers"
  add_foreign_key "users", "students"
  add_foreign_key "users", "trainers"
  add_foreign_key "workout_check_ins", "students"
  add_foreign_key "workout_check_ins", "workouts"
  add_foreign_key "workouts", "students"
end
