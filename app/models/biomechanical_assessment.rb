class BiomechanicalAssessment < ApplicationRecord
  belongs_to :student
  has_many :biomechanical_images, dependent: :destroy

  def images_map
    biomechanical_images.each_with_object({}) do |image, acc|
      acc[image.slot] = image.image_url
    end
  end
end
