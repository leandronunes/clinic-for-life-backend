class Exam < ApplicationRecord
  belongs_to :student

  validates :name, presence: true
  validates :file_url, presence: true

  before_validation { self.uploaded_at ||= Time.current }
end
