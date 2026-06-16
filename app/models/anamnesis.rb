class Anamnesis < ApplicationRecord
  belongs_to :student
  has_many :external_professionals, dependent: :destroy

  # Editable fields exposed by the dynamic anamnesis screen.
  FIELDS = %w[
    objectives
    medicines
    supplements
    systolic_pressure
    diastolic_pressure
    variable_glycemia
    notes
    height
    weight
    fracture
    dislocations
    pain
    orthopedic_notes
    meals
    hydration
    sleep
    stool
    urine
  ].freeze
end
