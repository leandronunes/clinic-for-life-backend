class EnableExtensions < ActiveRecord::Migration[8.1]
  def change
    return unless connection.adapter_name.start_with?("PostgreSQL")

    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")
  end
end
