class BackfillTrainerForAdminsWithoutOne < ActiveRecord::Migration[8.1]
  def up
    # Admin is a strict superset of personal (see AuthController's founder-admin
    # comment) — every admin needs a real Trainer row to be assignable as
    # trainer_id anywhere a personal already can be. Founder-admins already get
    # one at registration; this backfills everyone else (e.g. seeded/legacy admins).
    execute <<~SQL
      INSERT INTO trainers (name, email, organization_id, status, approved_at, created_at, updated_at)
      SELECT u.name, u.email, u.organization_id, 'active', NOW(), NOW(), NOW()
      FROM users u
      WHERE u.role = 'admin' AND u.trainer_id IS NULL
    SQL

    execute <<~SQL
      UPDATE users u
      SET trainer_id = t.id
      FROM trainers t
      WHERE u.role = 'admin' AND u.trainer_id IS NULL
        AND lower(t.email) = lower(u.email) AND t.organization_id = u.organization_id
    SQL
  end

  def down
    # Data backfill only — no structural change to reverse (same convention as
    # AddApprovedAtToTrainers#down, which doesn't try to undo its own backfill).
  end
end
