class AddApprovedAtToTrainers < ActiveRecord::Migration[8.1]
  def up
    add_column :trainers, :approved_at, :datetime
    # Todo trainer já existente nasce aprovado — a aprovação só passa a
    # importar pra quem entra numa organização já existente daqui pra frente.
    execute "UPDATE trainers SET approved_at = created_at"
  end

  def down
    remove_column :trainers, :approved_at
  end
end
