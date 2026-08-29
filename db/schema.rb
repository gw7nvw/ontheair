# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 0) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
  enable_extension "pg_catalog.plpgsql"
#  enable_extension "pg_stat_statements"
  enable_extension "postgis"
  enable_extension "postgres_fdw"
  enable_extension "unaccent"

  create_table "admin_settings", id: :serial, force: :cascade do |t|
    t.string "qrpnz_email", limit: 255
    t.string "admin_email", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "last_sota_activation_update_at", precision: nil
    t.datetime "last_sota_update_at", precision: nil
    t.datetime "last_pota_update_at", precision: nil
    t.datetime "last_wwff_update_at", precision: nil
    t.datetime "last_spot_read", precision: nil
    t.string "sota_epoch", limit: 255
    t.text "default_projection"
    t.text "default_layer"
    t.text "default_x"
    t.text "default_y"
    t.text "title"
    t.text "name"
    t.text "imagepath"
    t.string "sota_alert_epoch", limit: 255
    t.datetime "last_minute_sched_at", precision: nil
    t.datetime "last_monthly_sched_at", precision: nil
    t.string "last_sota_update_id", limit: 255
    t.string "last_pota_update_id", limit: 255
  end

  create_table "ak_maps", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "code", limit: 255
    t.geometry "WKT", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "location", limit: {srid: 4326, type: "st_point"}
  end

  create_table "asset_links", id: :serial, force: :cascade do |t|
    t.string "contained_code", limit: 255
    t.string "containing_code", limit: 255
    t.float "overlap"
    t.index ["contained_code"], name: "index_asset_links_on_contained_code"
    t.index ["containing_code"], name: "index_asset_links_on_containing_code"
  end

  create_table "asset_photo_links", id: :serial, force: :cascade do |t|
    t.string "asset_code", limit: 255
    t.string "link_url", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "photo_id"
  end

  create_table "asset_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "table_name", limit: 255
    t.boolean "has_location"
    t.boolean "has_boundary"
    t.string "index_name", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "display_name", limit: 255
    t.string "fields", limit: 255
    t.string "pnp_class", limit: 255
    t.boolean "keep_score"
    t.integer "min_qso"
    t.boolean "has_elevation"
    t.integer "ele_buffer"
    t.integer "dist_buffer"
    t.boolean "is_zlota"
    t.boolean "use_volcanic_field"
    t.boolean "use_az"
    t.boolean "use_within_sight"
    t.string "like_pattern", limit: 255
    t.index ["name"], name: "index_asset_types_on_name"
  end

  create_table "asset_web_links", id: :serial, force: :cascade do |t|
    t.string "asset_code", limit: 255
    t.string "url", limit: 255
    t.string "link_class", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "assets", id: :serial, force: :cascade do |t|
    t.string "asset_type", limit: 255
    t.string "code", limit: 255
    t.string "url", limit: 255
    t.string "name", limit: 255
    t.boolean "is_active"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "boundary", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "location", limit: {srid: 4326, type: "st_point"}
    t.string "safecode", limit: 255
    t.string "category", limit: 255
    t.boolean "minor"
    t.text "description"
    t.integer "altitude"
    t.integer "createdBy_id"
    t.integer "ref_id"
    t.string "land_district", limit: 255
    t.string "master_code", limit: 255
    t.string "region", limit: 255
    t.string "old_code", limit: 255
    t.float "area"
    t.integer "points"
    t.geometry "boundary_quite_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_very_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.string "district", limit: 255
    t.integer "nearest_road_id"
    t.integer "road_distance"
    t.datetime "valid_from", precision: nil
    t.datetime "valid_to", precision: nil
    t.boolean "is_nzart"
    t.string "access_road_ids", limit: 255, default: [], array: true
    t.string "access_legal_road_ids", limit: 255, default: [], array: true
    t.string "access_park_ids", limit: 255, default: [], array: true
    t.string "access_track_ids", limit: 255, default: [], array: true
    t.boolean "public_access"
    t.float "az_radius"
    t.string "field_code", limit: 255
    t.geometry "az_boundary", limit: {srid: 4326, type: "multi_polygon"}
    t.float "az_area"
    t.string "country", limit: 255
    t.string "state", limit: 255
    t.string "access_capad_park_ids", limit: 255, default: [], array: true
    t.string "access_vk_state_park_ids", limit: 255, default: [], array: true
    t.index "asset_type, COALESCE(boundary, location)", name: "idx_assets_type_and_spatial", using: :gist
    t.index "st_transform(boundary_quite_simplified, 3857)", name: "idx_assets_quite_simplified_3857", using: :gist
    t.index ["asset_type", "updated_at"], name: "index_assets_on_asset_type_and_updated_at"
    t.index ["asset_type"], name: "index_assets_on_asset_type"
    t.index ["boundary"], name: "assets_boundary_index", using: :gist
    t.index ["boundary_quite_simplified"], name: "assets_boundary_quite_simplified_index", using: :gist
    t.index ["boundary_simplified"], name: "assets_boundary_simplified_index", using: :gist
    t.index ["boundary_very_simplified"], name: "assets_boundary_very_simplified_index", using: :gist
    t.index ["code"], name: "index_assets_on_code"
    t.index ["location"], name: "assets_location_index", using: :gist
    t.index ["old_code"], name: "index_name"
    t.index ["safecode"], name: "index_assets_on_safecode"
    t.index ["updated_at"], name: "idx_assets_uppdated_at"
  end

  create_table "award_thresholds", id: :serial, force: :cascade do |t|
    t.integer "threshold"
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "award_user_links", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "award_id"
    t.boolean "notification_sent"
    t.boolean "acknowledged"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "threshold"
    t.string "award_type", limit: 255
    t.string "activity_type", limit: 255
    t.integer "linked_id"
    t.string "award_class", limit: 255
    t.datetime "expired_at", precision: nil
    t.boolean "expired"
  end

  create_table "awards", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.text "description"
    t.text "email_text"
    t.boolean "user_qrp"
    t.boolean "contact_qrp"
    t.boolean "is_active"
    t.integer "createdBy_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "allow_repeat_visits"
    t.boolean "count_based"
    t.boolean "activated"
    t.boolean "chased"
    t.string "programme", limit: 255
    t.boolean "all_district"
    t.boolean "all_region"
    t.boolean "all_programme"
    t.boolean "p2p"
  end

  create_table "bands", id: :serial, force: :cascade do |t|
    t.string "meter_band", limit: 255
    t.string "freq_band", limit: 255
    t.string "group", limit: 255
    t.float "min_frequency"
    t.float "max_frequency"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.text "comment"
    t.string "code", limit: 255
    t.integer "updated_by_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "consolidated_spots", id: :serial, force: :cascade do |t|
    t.string "time", limit: 255, default: [], array: true
    t.string "callsign", limit: 255, default: [], array: true
    t.string "activatorCallsign", limit: 255
    t.string "code", limit: 255, default: [], array: true
    t.string "name", limit: 255, default: [], array: true
    t.string "frequency", limit: 255
    t.string "mode", limit: 255
    t.string "comments", limit: 255, default: [], array: true
    t.string "spot_type", limit: 255, default: [], array: true
    t.string "post_id", limit: 255, default: [], array: true
    t.string "points", limit: 255
    t.string "altM", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "old_spot_type", limit: 255, default: [], array: true
    t.string "band", limit: 255
    t.string "dxcc", limit: 255
    t.string "continent", limit: 255
    t.index ["updated_at"], name: "idx_cs_updated_at"
  end

  create_table "contacts", id: :serial, force: :cascade do |t|
    t.string "callsign1", limit: 255
    t.integer "user1_id"
    t.integer "power1"
    t.string "signal1", limit: 255
    t.string "transceiver1", limit: 255
    t.string "antenna1", limit: 255
    t.string "comments1", limit: 255
    t.boolean "first_contact1", default: true
    t.string "loc_desc1", limit: 255
    t.float "x1"
    t.float "y1"
    t.integer "altitude1"
    t.string "callsign2", limit: 255
    t.integer "user2_id"
    t.integer "power2"
    t.string "signal2", limit: 255
    t.string "transceiver2", limit: 255
    t.string "antenna2", limit: 255
    t.string "comments2", limit: 255
    t.boolean "first_contact2", default: true
    t.string "loc_desc2", limit: 255
    t.float "x2"
    t.float "y2"
    t.integer "altitude2"
    t.datetime "date", precision: nil
    t.datetime "time", precision: nil
    t.string "timezone", limit: 255
    t.float "frequency"
    t.string "mode", limit: 255
    t.boolean "is_active", default: true
    t.integer "createdBy_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "location1", limit: {srid: 4326, type: "st_point"}
    t.geometry "location2", limit: {srid: 4326, type: "st_point"}
    t.boolean "is_qrp1"
    t.boolean "is_portable1"
    t.boolean "is_qrp2"
    t.boolean "is_portable2"
    t.integer "log_id"
    t.string "asset1_codes", limit: 255, default: [], array: true
    t.string "asset2_codes", limit: 255, default: [], array: true
    t.string "name1", limit: 255
    t.string "name2", limit: 255
    t.string "asset1_classes", limit: 255, default: [], array: true
    t.string "asset2_classes", limit: 255, default: [], array: true
    t.string "band", limit: 255
    t.string "loc_source2", limit: 255
    t.boolean "do_not_lookup"
    t.string "submitted_to", limit: 255, default: [], array: true
    t.index ["asset1_classes"], name: "idx_contacts_asset1_classes", using: :gin
    t.index ["asset1_codes"], name: "idx_contacts_asset1_codes_gin", using: :gin
    t.index ["asset2_classes"], name: "idx_contacts_asset2_classes", using: :gin
    t.index ["asset2_codes"], name: "idx_contacts_asset2_codes_gin", using: :gin
    t.index ["callsign1"], name: "index_contacts_on_callsign1"
    t.index ["callsign2"], name: "index_contacts_on_callsign2"
    t.index ["date", "time"], name: "idx_contacts_date_time"
    t.index ["date"], name: "index_contacts_on_date"
    t.index ["log_id"], name: "contacts_log_id_idx"
    t.index ["user1_id"], name: "contacts_user1id_idx"
    t.index ["user2_id"], name: "contacts_user2id_idx"
  end

  create_table "continents", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "code", limit: 255
  end

  create_table "crownparks", id: :serial, force: :cascade do |t|
    t.geometry "WKT", limit: {srid: 4326, type: "multi_polygon"}
    t.integer "napalis_id"
    t.string "start_date", limit: 255
    t.string "name", limit: 255
    t.string "recorded_area", limit: 255
    t.string "overlays", limit: 255
    t.string "reserve_type", limit: 255
    t.string "legislation", limit: 255
    t.string "section", limit: 255
    t.string "reserve_purpose", limit: 255
    t.string "ctrl_mg_vst", limit: 255
    t.boolean "is_active"
    t.integer "master_id"
    t.index ["WKT"], name: "docparks_wkt_index", using: :gist
  end

  create_table "districts", id: :serial, force: :cascade do |t|
    t.string "district_code", limit: 255
    t.string "region_code", limit: 255
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "boundary", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_quite_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_very_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.string "dxcc", limit: 255
    t.string "state_code", limit: 255
    t.index ["district_code"], name: "districts_district_code_idx"
    t.index ["region_code"], name: "districts_region_code_idx"
  end

  create_table "doc_tracks", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "object_type", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "linestring", limit: {srid: 4326, type: "multi_line_string"}
  end

  create_table "dxcc_prefixes", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "prefix", limit: 255
    t.string "itu_zone", limit: 255
    t.string "cq_zone", limit: 255
    t.string "continent_code", limit: 255
    t.string "dxcc_enum", limit: 255
    t.boolean "is_active"
    t.string "iso_code", limit: 255
    t.string "sms_gateway", limit: 255
  end

  create_table "email_blacklists", id: :serial, force: :cascade do |t|
    t.string "email_provider", limit: 255
  end

  create_table "external_activations", id: :serial, force: :cascade do |t|
    t.string "callsign", limit: 255
    t.string "summit_code", limit: 255
    t.integer "summit_sota_id"
    t.date "date"
    t.integer "qso_count"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.integer "external_activation_id"
    t.string "asset_type", limit: 255
    t.index ["asset_type"], name: "eas_asset_type_idx"
    t.index ["qso_count"], name: "eas_qso_count_idx"
    t.index ["user_id"], name: "eas_userid_idx"
  end

  create_table "external_alerts", id: :serial, force: :cascade do |t|
    t.datetime "starttime", precision: nil
    t.string "activatingCallsign", limit: 255
    t.string "code", limit: 255
    t.string "name", limit: 255
    t.string "frequency", limit: 255
    t.string "comments", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "mode", limit: 255
    t.string "programme", limit: 255
    t.string "duration", limit: 255
    t.string "dxcc", limit: 255
    t.string "continent", limit: 255
  end

  create_table "external_chases", id: :serial, force: :cascade do |t|
    t.string "callsign", limit: 255
    t.string "summit_code", limit: 255
    t.integer "summit_sota_id"
    t.integer "user_id"
    t.integer "external_activation_id"
    t.string "band", limit: 255
    t.string "mode", limit: 255
    t.date "date"
    t.time "time"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "asset_type", limit: 255
  end

  create_table "external_spots", id: :serial, force: :cascade do |t|
    t.datetime "time", precision: nil
    t.string "callsign", limit: 255
    t.string "activatorCallsign", limit: 255
    t.string "code", limit: 255
    t.string "name", limit: 255
    t.string "frequency", limit: 255
    t.string "mode", limit: 255
    t.string "comments", limit: 255
    t.string "spot_type", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "epoch", limit: 255
    t.boolean "is_test"
    t.string "points", limit: 255
    t.string "altM", limit: 255
    t.boolean "is_pnp"
    t.index ["time", "activatorCallsign"], name: "idx_external_spots_time_activator"
  end

  create_table "geological_eons", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.float "start_mya"
    t.float "end_mya"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "geological_epoches", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.float "start_mya"
    t.float "end_mya"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "geological_eras", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.float "start_mya"
    t.float "end_mya"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "geological_periods", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.float "start_mya"
    t.float "end_mya"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "humps", id: :serial, force: :cascade do |t|
    t.string "dxcc", limit: 255
    t.string "region", limit: 255
    t.string "code", limit: 255
    t.string "name", limit: 255
    t.string "elevation", limit: 255
    t.string "prominence", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "location", limit: {srid: 4326, type: "st_point"}
  end

  create_table "huts", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "hutbagger_link", limit: 255
    t.string "doc_link", limit: 255
    t.string "tramper_link", limit: 255
    t.string "routeguides_link", limit: 255
    t.string "general_link", limit: 255
    t.text "description"
    t.float "x"
    t.float "y"
    t.integer "altitude"
    t.boolean "is_active", default: true
    t.boolean "is_doc", default: true
    t.integer "createdBy_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "location", limit: {srid: 4326, type: "st_point"}
    t.string "code", limit: 255
    t.string "region", limit: 255
    t.string "dist_code", limit: 255
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.string "title", limit: 255
    t.text "description"
    t.string "filename", limit: 255
    t.string "image_file_name", limit: 255
    t.string "image_content_type", limit: 255
    t.integer "image_file_size"
    t.datetime "image_updated_at", precision: nil
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "post_id"
  end

  create_table "island_polygons", id: :serial, force: :cascade do |t|
    t.integer "name_id"
    t.string "name", limit: 255
    t.string "status", limit: 255
    t.integer "feat_id"
    t.string "feat_type", limit: 255
    t.string "nzgb_ref", limit: 255
    t.string "land_district", limit: 255
    t.string "crd_projection", limit: 255
    t.float "crd_north"
    t.float "crd_east"
    t.string "crd_datum", limit: 255
    t.float "crd_latitude"
    t.float "crd_longitude"
    t.text "info_ref"
    t.text "info_origin"
    t.text "info_description"
    t.text "info_note"
    t.text "feat_note"
    t.string "maori_name", limit: 255
    t.text "cpa_legislation"
    t.string "conservancy", limit: 255
    t.string "doc_cons_unit_no", limit: 255
    t.string "doc_gaz_ref", limit: 255
    t.string "treaty_legislation", limit: 255
    t.string "geom_type", limit: 255
    t.string "accuracy", limit: 255
    t.string "gebco", limit: 255
    t.string "region", limit: 255
    t.string "scufn", limit: 255
    t.string "height", limit: 255
    t.string "ant_pn_ref", limit: 255
    t.string "ant_pgaz_ref", limit: 255
    t.string "scar_id", limit: 255
    t.string "scar_rec_by", limit: 255
    t.string "accuracy_rating", limit: 255
    t.string "desc_code", limit: 255
    t.string "rev_gaz_ref", limit: 255
    t.string "rev_treaty_legislation", limit: 255
    t.integer "createdBy_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "WKT", limit: {srid: 4326, type: "multi_polygon"}
  end

  create_table "islands", id: :serial, force: :cascade do |t|
    t.integer "name_id"
    t.string "name", limit: 255
    t.string "status", limit: 255
    t.integer "feat_id"
    t.string "feat_type", limit: 255
    t.string "nzgb_ref", limit: 255
    t.string "land_district", limit: 255
    t.string "crd_projection", limit: 255
    t.float "crd_north"
    t.float "crd_east"
    t.string "crd_datum", limit: 255
    t.float "crd_latitude"
    t.float "crd_longitude"
    t.text "info_ref"
    t.text "info_origin"
    t.text "info_description"
    t.text "info_note"
    t.text "feat_note"
    t.string "maori_name", limit: 255
    t.text "cpa_legislation"
    t.string "conservancy", limit: 255
    t.string "doc_cons_unit_no", limit: 255
    t.string "doc_gaz_ref", limit: 255
    t.string "treaty_legislation", limit: 255
    t.string "geom_type", limit: 255
    t.string "accuracy", limit: 255
    t.string "gebco", limit: 255
    t.string "region", limit: 255
    t.string "scufn", limit: 255
    t.string "height", limit: 255
    t.string "ant_pn_ref", limit: 255
    t.string "ant_pgaz_ref", limit: 255
    t.string "scar_id", limit: 255
    t.string "scar_rec_by", limit: 255
    t.string "accuracy_rating", limit: 255
    t.string "desc_code", limit: 255
    t.string "rev_gaz_ref", limit: 255
    t.string "rev_treaty_legislation", limit: 255
    t.float "ref_point_X"
    t.float "ref_point_Y"
    t.integer "createdBy_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "WKT", limit: {srid: 4326, type: "st_point"}
    t.boolean "is_active", default: true
    t.string "general_link", limit: 255
    t.string "code", limit: 255
    t.geometry "boundary", limit: {srid: 4326, type: "multi_polygon"}
    t.string "dist_code", limit: 255
  end

  create_table "items", id: :serial, force: :cascade do |t|
    t.integer "topic_id"
    t.string "item_type", limit: 255
    t.integer "item_id"
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "legal_roads", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "boundary", limit: {srid: 4326, type: "multi_polygon"}
  end

  create_table "lighthouses", id: :serial, force: :cascade do |t|
    t.string "t50_fid", limit: 255
    t.string "loc_type", limit: 255
    t.string "status", limit: 255
    t.string "str_type", limit: 255
    t.string "name", limit: 255
    t.string "code", limit: 255
    t.string "region", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "location", limit: {srid: 4326, type: "st_point"}
    t.integer "mnz_id"
  end

  create_table "logs", id: :serial, force: :cascade do |t|
    t.string "callsign1", limit: 255
    t.integer "user1_id"
    t.integer "power1"
    t.string "signal1", limit: 255
    t.string "transceiver1", limit: 255
    t.string "antenna1", limit: 255
    t.string "comments1", limit: 255
    t.boolean "first_contact1", default: true
    t.string "loc_desc1", limit: 255
    t.integer "x1"
    t.integer "y1"
    t.integer "altitude1"
    t.datetime "date", precision: nil
    t.datetime "time", precision: nil
    t.string "timezone", limit: 255
    t.float "frequency"
    t.string "mode", limit: 255
    t.boolean "is_active", default: true
    t.integer "createdBy_id"
    t.boolean "is_qrp1"
    t.boolean "is_portable1"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "location1", limit: {srid: 4326, type: "st_point"}
    t.string "asset_codes", limit: 255, default: [], array: true
    t.integer "user_id"
    t.boolean "do_not_lookup"
    t.string "loc_source", limit: 255
    t.string "asset_classes", limit: 255, default: [], array: true
    t.boolean "qualified", default: [], array: true
    t.index ["asset_classes"], name: "idx_logs_asset_classes", using: :gin
    t.index ["date"], name: "index_logs_on_date"
    t.index ["user1_id"], name: "logs_user1id_idx"
  end

  create_table "maplayers", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "baseurl", limit: 255
    t.string "basemap", limit: 255
    t.integer "maxzoom"
    t.integer "minzoom"
    t.string "imagetype", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "copyright_text", limit: 255
    t.string "copyright_link", limit: 255
    t.string "extent", limit: 255
  end

  create_table "nz_tribal_lands", primary_key: "ogc_fid", id: :serial, force: :cascade do |t|
    t.geometry "wkb_geometry", limit: {srid: 4326, type: "multi_polygon"}
    t.decimal "id", precision: 10
    t.string "name", limit: 80
    t.string "country", limit: 255
    t.geometry "boundary_quite_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_very_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.index "st_transform(boundary_quite_simplified, 3857)", name: "idx_nz_tribal_lands_quite_simplified_3857", using: :gist
    t.index "st_transform(wkb_geometry, 3857)", name: "idx_tribal_lands_geom_3857", using: :gist
    t.index ["boundary_quite_simplified"], name: "idx_tribal_lands_boundary_quite_simplified", using: :gist
    t.index ["wkb_geometry"], name: "nz_tribal_lands_wkb_geometry_geom_idx", using: :gist
  end

  create_table "parks", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "doc_link", limit: 255
    t.string "tramper_link", limit: 255
    t.string "general_link", limit: 255
    t.text "description"
    t.boolean "is_active", default: true
    t.integer "createdBy_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "boundary", limit: {srid: 4326, type: "multi_polygon"}
    t.boolean "is_mr"
    t.string "owner", limit: 255
    t.geometry "location", limit: {srid: 4326, type: "st_point"}
    t.string "code", limit: 255
    t.integer "master_id"
    t.string "dist_code", limit: 255
    t.string "land_district", limit: 255
    t.string "region", limit: 255
  end

  create_table "posts", id: :serial, force: :cascade do |t|
    t.string "title", limit: 255
    t.text "description"
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "filename", limit: 255
    t.string "image_file_name", limit: 255
    t.string "image_content_type", limit: 255
    t.integer "image_file_size"
    t.datetime "image_updated_at", precision: nil
    t.boolean "do_not_publish"
    t.datetime "referenced_datetime", precision: nil
    t.datetime "referenced_date", precision: nil
    t.datetime "referenced_time", precision: nil
    t.integer "duration"
    t.string "site", limit: 255
    t.string "code", limit: 255
    t.string "mode", limit: 255
    t.string "freq", limit: 255
    t.boolean "is_hut"
    t.boolean "is_park"
    t.boolean "is_island"
    t.boolean "is_summit"
    t.string "hut", limit: 255
    t.string "park", limit: 255
    t.string "island", limit: 255
    t.string "summit", limit: 255
    t.string "callsign", limit: 255
    t.string "asset_codes", limit: 255, default: [], array: true
    t.integer "user_id"
    t.boolean "do_not_lookup"
    t.geometry "location", limit: {srid: 4326, type: "st_point"}
    t.string "loc_source", limit: 255
  end

  create_table "pota_parks", id: :serial, force: :cascade do |t|
    t.string "reference", limit: 255
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "location", limit: {srid: 4326, type: "st_point"}
    t.integer "park_id"
  end

  create_table "projections", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "proj4", limit: 255
    t.string "wkt", limit: 255
    t.integer "epsg"
    t.integer "createdBy_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "ratings", id: :serial, force: :cascade do |t|
    t.boolean "drive_up_access"
    t.boolean "track_access"
    t.integer "accessibility_score"
    t.integer "nice_score"
    t.integer "user_id"
    t.string "asset_code", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["asset_code"], name: "index_ratings_on_asset_code"
    t.index ["user_id"], name: "index_ratings_on_user_id"
  end

  create_table "regions", id: :serial, force: :cascade do |t|
    t.string "regc_code", limit: 255
    t.string "sota_code", limit: 255
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "boundary", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_quite_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_very_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.string "dxcc", limit: 255
    t.string "state_code", limit: 255
    t.index ["sota_code"], name: "regions_sota_code_idx"
  end

  create_table "roads", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "linestring", limit: {srid: 4326, type: "multi_line_string"}
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.text "session_id"
    t.text "data"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "sota_peaks", id: :serial, force: :cascade do |t|
    t.string "summit_code", limit: 255
    t.string "name", limit: 255
    t.string "short_code", limit: 255
    t.string "alt", limit: 255
    t.integer "points"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "location", limit: {srid: 4326, type: "st_point"}
    t.datetime "valid_from", precision: nil
    t.datetime "valid_to", precision: nil
  end

  create_table "sota_regions", id: :serial, force: :cascade do |t|
    t.string "dxcc", limit: 255
    t.string "region", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "states", id: :serial, force: :cascade do |t|
    t.string "code", limit: 255
    t.string "pnp_code", limit: 255
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "dxcc", limit: 255
    t.geometry "boundary", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_quite_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_very_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.index ["boundary"], name: "states_geom_idx", using: :gist
  end

  create_table "timezones", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "description", limit: 255
    t.integer "difference"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "topics", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.text "description"
    t.integer "owner_id"
    t.boolean "is_public"
    t.boolean "is_owners"
    t.datetime "last_updated", precision: nil
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "is_members_only"
    t.boolean "date_required"
    t.boolean "allow_mail"
    t.boolean "duration_required"
    t.boolean "is_alert"
    t.boolean "is_spot"
    t.boolean "allow_attachments"
  end

  create_table "uploads", id: :serial, force: :cascade do |t|
    t.string "doc_file_name", limit: 255
    t.string "doc_content_type", limit: 255
    t.integer "doc_file_size"
    t.datetime "doc_updated_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "doc_callsign", limit: 255
    t.boolean "doc_no_create"
    t.boolean "doc_ignore_error"
    t.string "doc_location", limit: 255
  end

  create_table "user_agents", id: :serial, force: :cascade do |t|
    t.integer "access_count", default: 0, null: false
    t.text "user_ip", null: false
    t.boolean "suspected_bot"
    t.boolean "confirmed_bot"
    t.integer "suspicious_access_count", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "html_count", default: 0, null: false
    t.integer "js_count", default: 0, null: false
    t.boolean "confirmed_human"
    t.index ["user_ip"], name: "index_user_agents_on_user_ip"
  end

  create_table "user_callsigns", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "callsign", limit: 255
    t.datetime "from_date", precision: nil
    t.datetime "to_date", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["callsign", "from_date", "to_date"], name: "idx_user_callsigns_lookup"
  end

  create_table "user_tokens", id: :serial, force: :cascade do |t|
    t.string "remember_token", limit: 255
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "user_topic_links", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "topic_id"
    t.boolean "mail"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "notification"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "callsign", limit: 255
    t.string "email", limit: 255
    t.string "firstname", limit: 255
    t.string "lastname", limit: 255
    t.string "password_digest", limit: 255
    t.string "remember_token", limit: 255
    t.string "activation_digest", limit: 255
    t.boolean "activated", default: false
    t.datetime "activated_at", precision: nil
    t.boolean "is_admin", default: false
    t.boolean "is_active", default: true
    t.boolean "is_modifier", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "reset_digest", limit: 255
    t.datetime "reset_sent_at", precision: nil
    t.integer "timezone"
    t.boolean "membership_requested"
    t.boolean "membership_confirmed"
    t.string "home_qth", limit: 255
    t.string "mailuser", limit: 255
    t.boolean "group_admin"
    t.string "remember_token2", limit: 255
    t.string "score", limit: 255
    t.string "score_total", limit: 255
    t.string "activated_count", limit: 255
    t.string "activated_count_total", limit: 255
    t.string "chased_count", limit: 255
    t.string "chased_count_total", limit: 255
    t.boolean "outstanding"
    t.string "pin", limit: 255
    t.boolean "allow_pnp_login"
    t.datetime "hide_news_at", precision: nil
    t.boolean "read_only"
    t.string "acctnumber", limit: 255
    t.boolean "logs_pota"
    t.boolean "logs_wwff"
    t.string "qualified_count", limit: 255
    t.string "qualified_count_total", limit: 255
    t.string "confirmed_activated_count", limit: 255
    t.string "confirmed_activated_count_total", limit: 255
    t.string "polygonlayers", limit: 255
    t.string "pointlayers", limit: 255
    t.boolean "is_web_admin"
    t.string "push_app_token", limit: 255
    t.string "push_user_token", limit: 255
    t.boolean "push_include_comments"
    t.boolean "push_include_map"
    t.string "push_external_filter", limit: 255
    t.boolean "push_include_external"
    t.string "dxcc", limit: 255
    t.string "baselayer", limit: 255
    t.string "pnp_APIKey", limit: 255
    t.boolean "pnp_imported", default: false
    t.string "pnp_username", limit: 255
    t.index ["callsign"], name: "index_users_on_callsign"
    t.index ["remember_token"], name: "index_users_on_remember_token"
  end

  create_table "vk_assets", id: :serial, force: :cascade do |t|
    t.string "award", limit: 255
    t.string "wwff_code", limit: 255
    t.string "pota_code", limit: 255
    t.string "shire_code", limit: 255
    t.string "state", limit: 255
    t.string "region", limit: 255
    t.string "district", limit: 255
    t.string "code", limit: 255
    t.string "name", limit: 255
    t.string "site_type", limit: 255
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "location", limit: {srid: 4326, type: "st_point"}
    t.geometry "boundary", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_quite_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_very_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.integer "caped_id"
    t.float "area"
    t.boolean "is_active"
    t.string "url", limit: 255
    t.string "asset_type", limit: 255
    t.text "description"
    t.string "old_code", limit: 255
    t.index ["award"], name: "vk_award_indx"
    t.index ["code"], name: "vk_code_indx"
  end

  create_table "vk_lakes", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "volcanic_fields", id: :serial, force: :cascade do |t|
    t.string "code", limit: 255
    t.string "name", limit: 255
    t.string "period", limit: 255
    t.string "epoch", limit: 255
    t.string "eon", limit: 255
    t.string "era", limit: 255
    t.float "min_age"
    t.float "max_age"
    t.string "description", limit: 255
    t.geometry "location", limit: {srid: 4326, type: "st_point"}
    t.geometry "boundary", limit: {srid: 4326, type: "multi_polygon"}
    t.string "url", limit: 255
    t.geometry "boundary_quite_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_simplified", limit: {srid: 4326, type: "multi_polygon"}
    t.geometry "boundary_very_simplified", limit: {srid: 4326, type: "multi_polygon"}
  end

  create_table "volcanos", id: :serial, force: :cascade do |t|
    t.string "code", limit: 255
    t.string "name", limit: 255
    t.string "status", limit: 255
    t.string "field_name", limit: 255
    t.float "age"
    t.string "period", limit: 255
    t.string "epoch", limit: 255
    t.integer "height"
    t.float "lat"
    t.float "long"
    t.float "az_radius"
    t.string "url", limit: 255
    t.string "description", limit: 255
    t.geometry "location", limit: {srid: 4326, type: "st_point"}
    t.string "eon", limit: 255
    t.string "era", limit: 255
    t.float "min_age"
    t.float "max_age"
    t.string "date_range", limit: 255
    t.string "field_code", limit: 255
  end

  create_table "volcanos_raw", primary_key: "gid", id: :serial, force: :cascade do |t|
    t.string "descr", limit: 254
    t.string "typename", limit: 50
    t.string "geolhist", limit: 254
    t.string "repage_uri", limit: 150
    t.string "yngage_uri", limit: 150
    t.string "oldage_uri", limit: 150
    t.string "stratage", limit: 50
    t.float "absmin_ma"
    t.float "absmax_ma"
    t.string "stratrank", limit: 50
    t.string "mbrequiv", limit: 150
    t.string "fmnequiv", limit: 254
    t.string "sbgrpequiv", limit: 150
    t.string "grpequiv", limit: 150
    t.string "spgrpequiv", limit: 150
    t.string "terrequiv", limit: 150
    t.string "megaequiv", limit: 150
    t.string "stratlex", limit: 100
    t.string "litho2014", limit: 100
    t.string "lithology", limit: 150
    t.string "mainrock", limit: 50
    t.string "subrocks", limit: 150
    t.string "protolith", limit: 150
    t.string "tzone", limit: 10
    t.string "rockgroup", limit: 50
    t.string "rockclass", limit: 50
    t.string "simplename", limit: 254
    t.string "keygrpname", limit: 100
    t.string "volc_name", limit: 80
    t.string "group_code", limit: 10
  end

  create_table "web_link_classes", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "display_name", limit: 255
    t.string "url", limit: 255
    t.boolean "is_active"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "wishlists", id: :serial, force: :cascade do |t|
    t.string "asset_code", limit: 255
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["asset_code"], name: "index_wishlists_on_asset_code"
    t.index ["user_id"], name: "index_wishlists_on_user_id"
  end

  create_table "wwff_parks", id: :serial, force: :cascade do |t|
    t.string "code", limit: 255
    t.string "name", limit: 255
    t.string "dxcc", limit: 255
    t.string "region", limit: 255
    t.string "notes", limit: 255
    t.integer "napalis_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.geometry "location", limit: {srid: 4326, type: "st_point"}
  end
end
