class BioimpedanceImport < ApplicationRecord
  belongs_to :trainer, optional: true

  validates :filename, presence: true
end
