class AddSoloToOrganizations < ActiveRecord::Migration[8.1]
  def up
    add_column :organizations, :solo, :boolean, null: false, default: false

    # Backfill: every solo-trainer organization created so far follows the
    # exact naming convention from AuthController#build_trainer_for_registration!
    # ("#{name} (individual)") — there's no other marker to derive this from
    # for rows created before this column existed.
    execute "UPDATE organizations SET solo = true WHERE name LIKE '% (individual)'"
  end

  def down
    remove_column :organizations, :solo
  end
end
