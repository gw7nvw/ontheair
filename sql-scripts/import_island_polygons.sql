SELECT UpdateGeometrySRID('island_polygons','WKT',0);
copy island_polygons ("WKT","name_id","feat_id","name","status","feat_type","nzgb_ref","land_district","crd_projection","crd_north","crd_east","crd_datum","crd_latitude","crd_longitude","info_ref","info_origin","info_note","feat_note","info_description","maori_name","cpa_legislation","conservancy","doc_cons_unit_no","doc_gaz_ref","treaty_legislation","geom_type","accuracy","gebco","region","scufn","height","ant_pn_ref","ant_pgaz_ref","scar_id","scar_rec_by","accuracy_rating","desc_code","rev_gaz_ref","rev_treaty_legislation") from '/home/mbriggs/island_polygons.csv' delimiter ',' quote '"' csv HEADER;
SELECT UpdateGeometrySRID('island_polygons','WKT',4326);
delete from island_polygons where feat_type not like 'Island';
