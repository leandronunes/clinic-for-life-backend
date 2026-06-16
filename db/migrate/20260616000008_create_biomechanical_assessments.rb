class CreateBiomechanicalAssessments < ActiveRecord::Migration[8.1]
  def change
    create_table :biomechanical_assessments do |t|
      t.references :student, null: false, foreign_key: true

      t.timestamps
    end

    create_table :biomechanical_images do |t|
      t.references :biomechanical_assessment, null: false, foreign_key: true
      t.string :slot, null: false
      t.string :image_url, null: false

      t.timestamps
    end

    add_index :biomechanical_images, [ :biomechanical_assessment_id, :slot ],
              unique: true, name: "index_biomechanical_images_on_assessment_and_slot"
  end
end
