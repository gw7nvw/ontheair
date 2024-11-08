class AddSimpleBoundaryToVolcanicFields < ActiveRecord::Migration
  def change
      add_column :volcanic_fields, :boundary_quite_simplified, :multi_polygon,    srid: 4326
      add_column :volcanic_fields, :boundary_simplified, :multi_polygon,    srid: 4326
      add_column :volcanic_fields, :boundary_very_simplified, :multi_polygon,    srid: 4326

  end
end
