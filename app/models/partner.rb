class Partner < ApplicationRecord
  belongs_to :organization

  validates :name, presence: true
  validates :category, presence: true
end
