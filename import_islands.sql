SELECT UpdateGeometrySRID('islands','WKT',0);
copy islands ("WKT","name_id","name","status","feat_id","feat_type","nzgb_ref","land_district","crd_projection","crd_north","crd_east","crd_datum","crd_latitude","crd_longitude","info_ref","info_origin","info_description","info_note","feat_note","maori_name","cpa_legislation","conservancy","doc_cons_unit_no","doc_gaz_ref","treaty_legislation","geom_type","accuracy","gebco","region","scufn","height","ant_pn_ref","ant_pgaz_ref","scar_id","scar_rec_by","accuracy_rating","desc_code","rev_gaz_ref","rev_treaty_legislation","ref_point_X","ref_point_Y") from '/home/mbriggs/islands.csv' delimiter ',' quote '"' csv HEADER;
SELECT UpdateGeometrySRID('islands','WKT',4326);
update islands set id = id+1000000;
update islands set id = "name_id";
delete from islands where feat_type not like 'Island';
