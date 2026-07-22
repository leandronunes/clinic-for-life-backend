class CreateOrganizationsAndBackfillDefaultTenant < ActiveRecord::Migration[8.1]
  def up
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :domain, null: false
      t.timestamps
    end
    add_index :organizations, :domain, unique: true

    add_reference :users, :organization, foreign_key: true
    add_reference :trainers, :organization, foreign_key: true
    add_reference :students, :organization, foreign_key: true
    add_reference :partners, :organization, foreign_key: true

    # Organização padrão pra abrigar todo o dado hoje existente — o admin
    # legado, todos os trainers/students (e, por consequência, tudo que
    # resolve escopo via trainer_id/student_id), e o catálogo de parceiros
    # hoje global viram "uma organização" só, preservando o comportamento
    # observável de hoje (só existe 1 tenant).
    default_org_id = execute(<<~SQL).first["id"]
      INSERT INTO organizations (name, domain, created_at, updated_at)
      VALUES ('Clínica For Life', 'clinica-for-life', NOW(), NOW())
      RETURNING id
    SQL

    execute "UPDATE users SET organization_id = #{default_org_id}"
    execute "UPDATE trainers SET organization_id = #{default_org_id}"
    execute "UPDATE students SET organization_id = #{default_org_id}"
    execute "UPDATE partners SET organization_id = #{default_org_id}"

    change_column_null :users, :organization_id, false
    change_column_null :trainers, :organization_id, false
    change_column_null :students, :organization_id, false
    change_column_null :partners, :organization_id, false
  end

  def down
    remove_reference :partners, :organization, foreign_key: true
    remove_reference :students, :organization, foreign_key: true
    remove_reference :trainers, :organization, foreign_key: true
    remove_reference :users, :organization, foreign_key: true
    drop_table :organizations
  end
end
