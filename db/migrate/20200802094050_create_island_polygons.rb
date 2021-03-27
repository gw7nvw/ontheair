class CreateIslandPolygons < ActiveRecord::Migration
  def change
    create_table :island_polygons do |t|
    t.multi_polygon :WKT, :spatial => true, :srid => 4326
    t.integer :name_id
    t.string :name
    t.string :status
    t.integer :feat_id
    t.string :feat_type
    t.string :nzgb_ref
    t.string :land_district
    t.string :crd_projection
    t.float :crd_north
    t.float :crd_east
    t.string :crd_datum
    t.float :crd_latitude
    t.float :crd_longitude
    t.text :info_ref
    t.text :info_origin
    t.text :info_description
    t.text :info_note
    t.text :feat_note
    t.string :maori_name
    t.text :cpa_legislation
    t.string :conservancy
    t.string :doc_cons_unit_no
    t.string :doc_gaz_ref
    t.string :treaty_legislation
    t.string :geom_type
    t.string :accuracy
    t.string :gebco
    t.string :region
    t.string :scufn
    t.string :height
    t.string :ant_pn_ref
    t.string :ant_pgaz_ref
    t.string :scar_id
    t.string :scar_rec_by
    t.string :accuracy_rating
    t.string :desc_code
    t.string :rev_gaz_ref
    t.string :rev_treaty_legislation

      t.integer :createdBy_id

      t.timestamps
    end
  end
end
