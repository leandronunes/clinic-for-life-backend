class RemoveKindFromFeedbacks < ActiveRecord::Migration[8.1]
  def change
    remove_column :feedbacks, :kind, :string
  end
end
