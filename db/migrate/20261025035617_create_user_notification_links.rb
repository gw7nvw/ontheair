class CreateUserNotificationLinks < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')

    create_table :user_notification_links do |t|
      t.integer :user_id, null: false

      # Exact match arrays (Defaulting to empty array to match your consolidated_spots pattern)
      t.string :continents, array: true, default: []
      t.string :bands,      array: true, default: []
      t.string :modes,      array: true, default: []
      t.string :spot_types, array: true, default: []

      # Free-text wildcard columns (Stored uppercase in application layer)
      t.string :activator_callsign
      t.string :code

      # Priority
      t.integer :priority, default: 0, null: false

      t.timestamps

    # 2. Add an explicit foreign key or index on user_id for relational hygiene
    t.index :user_id
    end
    # 3. Add a multi-column GIN index for the multi-select array lookups
    add_index :user_notification_links,
              [ :continents, :bands, :modes, :spot_types ],
              name: 'idx_unl_arrays',
              using: :gin

    # 4. Add Trigram GIN indexes for sub-millisecond wildcard/LIKE queries
    add_index :user_notification_links, :activator_callsign, name: 'idx_unl_activator_trgm', using: :gin, opclass: :gin_trgm_ops
    add_index :user_notification_links, :code,               name: 'idx_unl_code_trgm',      using: :gin, opclass: :gin_trgm_ops
  end
end
