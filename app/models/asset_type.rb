class AssetType < ActiveRecord::Base

def self.seed
  a=AssetType.create(name: 'all', table_name: 'Asset', has_location: true, has_boundary:true, index_name: 'code', display_name: 'All', fields: "", pnp_class: "", keep_score: false)
  a=AssetType.create(name: 'park', table_name: 'Park', has_location: true, has_boundary:true, index_name: 'code', display_name: 'Park', fields: "", pnp_class: "ZLOTA", keep_score: true)
  a=AssetType.create(name: 'hut', table_name: 'Hut', has_location: true, has_boundary:false, index_name: 'code', display_name: 'Hut', fields: "", pnp_class: "ZLOTA", keep_score: true)
  a=AssetType.create(name: 'island', table_name: 'Island', has_location: true, has_boundary:true, index_name: 'code', display_name: 'Island', fields: "status,info_ref,info_origin,info_note", pnp_class: "ZLOTA" , keep_score: true)
  a=AssetType.create(name: 'summit', table_name: 'SotaPeak', has_location: true, has_boundary:false, index_name: 'summit_code', display_name: 'SOTA Summit', fields: "", pnp_class: "", keep_score: false)
  a=AssetType.create(name: 'pota park', table_name: 'PotaPark', has_location: true, has_boundary:true, index_name: 'reference', display_name: ' POTA Park', fields: "", pnp_class: "POTA", keep_score: false)
  a=AssetType.create(name: 'wwff park', table_name: 'WwffPark', has_location: true, has_boundary:true, index_name: 'code', display_name: 'WWFF Park', fields: "", pnp_class: "WWFF", keep_score: false)
  a=AssetType.create(name: 'lake', table_name: 'Lake', has_location: true, has_boundary:true, index_name: 'code', display_name: 'Lake', fields: "info_origin", pnp_class: "ZLOTA", keep_score: true)
end

end
