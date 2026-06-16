class CreateStructuralAssessments < ActiveRecord::Migration[8.1]
  def change
    create_table :structural_assessments do |t|
      t.references :student, null: false, foreign_key: true, index: { unique: true }
      t.boolean :scoliosis, null: false, default: false
      t.boolean :spine_rotation, null: false, default: false
      t.boolean :hip_rotation, null: false, default: false
      t.boolean :scapular_girdle_imbalance, null: false, default: false
      t.boolean :scapular_dyskinesis, null: false, default: false
      t.boolean :shortening, null: false, default: false
      t.boolean :limb_length_difference, null: false, default: false
      t.boolean :pelvic_anteversion, null: false, default: false
      t.boolean :pelvic_retroversion, null: false, default: false
      t.boolean :knee_valgus, null: false, default: false
      t.boolean :knee_varus, null: false, default: false
      t.boolean :cavus_foot_arch, null: false, default: false
      t.boolean :flat_foot_arch, null: false, default: false

      t.timestamps
    end
  end
end
