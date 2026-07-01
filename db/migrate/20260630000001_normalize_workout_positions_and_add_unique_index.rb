class NormalizeWorkoutPositionsAndAddUniqueIndex < ActiveRecord::Migration[8.1]
  def up
    # Renumber positions per (student, status) group so each group is sequential from 1.
    # Uses ROW_NUMBER() to handle existing duplicates before adding the unique constraint.
    execute <<~SQL
      UPDATE workouts w
      SET position = sub.new_position
      FROM (
        SELECT id,
               ROW_NUMBER() OVER (PARTITION BY student_id, status ORDER BY position, id) AS new_position
        FROM workouts
      ) sub
      WHERE w.id = sub.id
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_workouts_on_student_active_position
      ON workouts (student_id, position) WHERE (status = 'active')
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_workouts_on_student_archived_position
      ON workouts (student_id, position) WHERE (status = 'archived')
    SQL
  end

  def down
    remove_index :workouts, name: "index_workouts_on_student_active_position"
    remove_index :workouts, name: "index_workouts_on_student_archived_position"
  end
end
