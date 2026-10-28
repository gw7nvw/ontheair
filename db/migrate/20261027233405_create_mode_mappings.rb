class CreateModeMappings < ActiveRecord::Migration[8.0]
  def change
    create_table :mode_mappings do |t|
      t.string :raw_mode, null: false      # e.g., 'LSB', 'USB', 'FT8'
      t.string :parent_group, null: false  # e.g., 'SSB', 'SSB', 'DIGI'
      t.timestamps
    end

    add_index :mode_mappings, :raw_mode, unique: true
    add_index :mode_mappings, :parent_group
  end
end
