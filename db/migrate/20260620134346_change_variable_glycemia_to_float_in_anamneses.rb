class ChangeVariableGlycemiaToFloatInAnamneses < ActiveRecord::Migration[8.1]
  NUMERIC_COLUMNS = %w[variable_glycemia systolic_pressure diastolic_pressure height weight].freeze

  def up
    NUMERIC_COLUMNS.each do |col|
      execute <<~SQL
        ALTER TABLE anamneses
          ALTER COLUMN #{col} TYPE float
          USING NULLIF(#{col}, '')::float
      SQL
    end
  end

  def down
    NUMERIC_COLUMNS.each do |col|
      execute <<~SQL
        ALTER TABLE anamneses
          ALTER COLUMN #{col} TYPE varchar
          USING #{col}::text
      SQL
    end
  end
end
