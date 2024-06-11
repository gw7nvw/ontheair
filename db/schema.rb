# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20240412000213) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "postgres_fdw"
  enable_extension "unaccent"

  create_table "admin_settings", force: true do |t|
    t.string   "qrpnz_email"
    t.string   "admin_email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_sota_activation_update_at"
    t.datetime "last_sota_update_at"
    t.datetime "last_pota_update_at"
    t.datetime "last_wwff_update_at"
    t.datetime "last_spot_read"
  end

  create_table "ak_maps", force: true do |t|
    t.string  "name"
    t.string  "code"
    t.spatial "WKT",      limit: {:srid=>4326, :type=>"multi_polygon"}
    t.spatial "location", limit: {:srid=>4326, :type=>"point"}
  end

  create_table "asset_links", force: true do |t|
    t.string "parent_code"
    t.string "child_code"
  end

  add_index "asset_links", ["child_code"], :name => "index_asset_links_on_child_code"
  add_index "asset_links", ["parent_code"], :name => "index_asset_links_on_parent_code"

  create_table "asset_photo_links", force: true do |t|
    t.string   "asset_code"
    t.string   "link_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "photo_id"
  end

  create_table "asset_types", force: true do |t|
    t.string   "name"
    t.string   "table_name"
    t.boolean  "has_location"
    t.boolean  "has_boundary"
    t.string   "index_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "display_name"
    t.string   "fields"
    t.string   "pnp_class"
    t.boolean  "keep_score"
    t.integer  "min_qso"
  end

  add_index "asset_types", ["name"], :name => "index_asset_types_on_name"

  create_table "asset_web_links", force: true do |t|
    t.string   "asset_code"
    t.string   "url"
    t.string   "link_class"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assets", force: true do |t|
    t.string   "asset_type"
    t.string   "code"
    t.string   "url"
    t.string   "name"
    t.boolean  "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "boundary",                  limit: {:srid=>4326, :type=>"multi_polygon"}
    t.spatial  "location",                  limit: {:srid=>4326, :type=>"point"}
    t.string   "safecode"
    t.string   "category"
    t.boolean  "minor"
    t.text     "description"
    t.integer  "altitude"
    t.integer  "createdBy_id"
    t.integer  "ref_id"
    t.string   "land_district"
    t.string   "master_code"
    t.string   "region"
    t.string   "old_code"
    t.float    "area"
    t.integer  "points"
    t.spatial  "boundary_quite_simplified", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.spatial  "boundary_simplified",       limit: {:srid=>4326, :type=>"multi_polygon"}
    t.spatial  "boundary_very_simplified",  limit: {:srid=>4326, :type=>"multi_polygon"}
    t.string   "district"
    t.integer  "nearest_road_id"
    t.integer  "road_distance"
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.boolean  "is_nzart"
    t.string   "access_road_ids",                                                         default: [], array: true
    t.string   "access_legal_road_ids",                                                   default: [], array: true
    t.string   "access_park_ids",                                                         default: [], array: true
    t.string   "access_track_ids",                                                        default: [], array: true
    t.boolean  "public_access"
    t.integer  "az_radius"
  end

  add_index "assets", ["asset_type"], :name => "index_assets_on_asset_type"
  add_index "assets", ["boundary"], :name => "assets_boundary_index", :spatial => true
  add_index "assets", ["boundary_quite_simplified"], :name => "assets_boundary_quite_simplified_index", :spatial => true
  add_index "assets", ["boundary_simplified"], :name => "assets_boundary_simplified_index", :spatial => true
  add_index "assets", ["boundary_very_simplified"], :name => "assets_boundary_very_simplified_index", :spatial => true
  add_index "assets", ["code"], :name => "index_assets_on_code"
  add_index "assets", ["location"], :name => "assets_location_index", :spatial => true
  add_index "assets", ["safecode"], :name => "index_assets_on_safecode"

  create_table "award_thresholds", force: true do |t|
    t.integer  "threshold"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "award_user_links", force: true do |t|
    t.integer  "user_id"
    t.integer  "award_id"
    t.boolean  "notification_sent"
    t.boolean  "acknowledged"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "threshold"
    t.string   "award_type"
    t.string   "activity_type"
    t.integer  "linked_id"
    t.string   "award_class"
    t.datetime "expired_at"
    t.boolean  "expired"
  end

  create_table "awards", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.text     "email_text"
    t.boolean  "user_qrp"
    t.boolean  "contact_qrp"
    t.boolean  "is_active"
    t.integer  "createdBy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "allow_repeat_visits"
    t.boolean  "count_based"
    t.boolean  "activated"
    t.boolean  "chased"
    t.string   "programme"
    t.boolean  "all_district"
    t.boolean  "all_region"
    t.boolean  "all_programme"
    t.boolean  "p2p"
  end

  create_table "comments", force: true do |t|
    t.text     "comment"
    t.string   "code"
    t.integer  "updated_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "contacts", force: true do |t|
    t.string   "callsign1"
    t.integer  "user1_id"
    t.integer  "power1"
    t.string   "signal1"
    t.string   "transceiver1"
    t.string   "antenna1"
    t.string   "comments1"
    t.boolean  "first_contact1",                                          default: true
    t.string   "loc_desc1"
    t.integer  "x1"
    t.integer  "y1"
    t.integer  "altitude1"
    t.string   "callsign2"
    t.integer  "user2_id"
    t.integer  "power2"
    t.string   "signal2"
    t.string   "transceiver2"
    t.string   "antenna2"
    t.string   "comments2"
    t.boolean  "first_contact2",                                          default: true
    t.string   "loc_desc2"
    t.integer  "x2"
    t.integer  "y2"
    t.integer  "altitude2"
    t.datetime "date"
    t.datetime "time"
    t.string   "timezone"
    t.float    "frequency"
    t.string   "mode"
    t.boolean  "is_active",                                               default: true
    t.integer  "createdBy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "location1",         limit: {:srid=>4326, :type=>"point"}
    t.spatial  "location2",         limit: {:srid=>4326, :type=>"point"}
    t.boolean  "is_qrp1"
    t.boolean  "is_portable1"
    t.boolean  "is_qrp2"
    t.boolean  "is_portable2"
    t.boolean  "submitted_to_pota"
    t.boolean  "submitted_to_wwff"
    t.boolean  "submitted_to_sota"
    t.integer  "log_id"
    t.string   "asset1_codes",                                            default: [],   array: true
    t.string   "asset2_codes",                                            default: [],   array: true
    t.string   "name1"
    t.string   "name2"
    t.string   "asset1_classes",                                          default: [],   array: true
    t.string   "asset2_classes",                                          default: [],   array: true
  end

  add_index "contacts", ["callsign1"], :name => "index_contacts_on_callsign1"
  add_index "contacts", ["callsign2"], :name => "index_contacts_on_callsign2"

  create_table "continents", force: true do |t|
    t.string "name"
    t.string "code"
  end

  create_table "crownparks", force: true do |t|
    t.spatial "WKT",             limit: {:srid=>4326, :type=>"multi_polygon"}
    t.integer "napalis_id"
    t.string  "start_date"
    t.string  "name"
    t.string  "recorded_area"
    t.string  "overlays"
    t.string  "reserve_type"
    t.string  "legislation"
    t.string  "section"
    t.string  "reserve_purpose"
    t.string  "ctrl_mg_vst"
    t.boolean "is_active"
    t.integer "master_id"
  end

  add_index "crownparks", ["WKT"], :name => "docparks_wkt_index", :spatial => true

  create_table "districts", force: true do |t|
    t.string   "district_code"
    t.string   "region_code"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "boundary",                  limit: {:srid=>4326, :type=>"multi_polygon"}
    t.spatial  "boundary_quite_simplified", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.spatial  "boundary_simplified",       limit: {:srid=>4326, :type=>"multi_polygon"}
    t.spatial  "boundary_very_simplified",  limit: {:srid=>4326, :type=>"multi_polygon"}
  end

  create_table "doc_tracks", force: true do |t|
    t.string   "name"
    t.string   "object_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "linestring",  limit: {:srid=>4326, :type=>"multi_line_string"}
  end

  create_table "dxcc_prefixes", force: true do |t|
    t.string "name"
    t.string "prefix"
    t.string "itu_zone"
    t.string "cq_zone"
    t.string "continent_code"
  end

  create_table "external_spots", force: true do |t|
    t.datetime "time"
    t.string   "callsign"
    t.string   "activatorCallsign"
    t.string   "code"
    t.string   "name"
    t.string   "frequency"
    t.string   "mode"
    t.string   "comments"
    t.string   "spot_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "humps", force: true do |t|
    t.string   "dxcc"
    t.string   "region"
    t.string   "code"
    t.string   "name"
    t.string   "elevation"
    t.string   "prominence"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "location",   limit: {:srid=>4326, :type=>"point"}
  end

  create_table "hut_photo_links", force: true do |t|
    t.integer  "hut_id"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "huts", force: true do |t|
    t.string   "name"
    t.string   "hutbagger_link"
    t.string   "doc_link"
    t.string   "tramper_link"
    t.string   "routeguides_link"
    t.string   "general_link"
    t.text     "description"
    t.float    "x"
    t.float    "y"
    t.integer  "altitude"
    t.boolean  "is_active",                                              default: true
    t.boolean  "is_doc",                                                 default: true
    t.integer  "createdBy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "location",         limit: {:srid=>4326, :type=>"point"}
    t.string   "code"
    t.string   "region"
    t.string   "dist_code"
  end

  create_table "images", force: true do |t|
    t.string   "title"
    t.text     "description"
    t.string   "filename"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "post_id"
  end

  create_table "island_polygons", force: true do |t|
    t.integer  "name_id"
    t.string   "name"
    t.string   "status"
    t.integer  "feat_id"
    t.string   "feat_type"
    t.string   "nzgb_ref"
    t.string   "land_district"
    t.string   "crd_projection"
    t.float    "crd_north"
    t.float    "crd_east"
    t.string   "crd_datum"
    t.float    "crd_latitude"
    t.float    "crd_longitude"
    t.text     "info_ref"
    t.text     "info_origin"
    t.text     "info_description"
    t.text     "info_note"
    t.text     "feat_note"
    t.string   "maori_name"
    t.text     "cpa_legislation"
    t.string   "conservancy"
    t.string   "doc_cons_unit_no"
    t.string   "doc_gaz_ref"
    t.string   "treaty_legislation"
    t.string   "geom_type"
    t.string   "accuracy"
    t.string   "gebco"
    t.string   "region"
    t.string   "scufn"
    t.string   "height"
    t.string   "ant_pn_ref"
    t.string   "ant_pgaz_ref"
    t.string   "scar_id"
    t.string   "scar_rec_by"
    t.string   "accuracy_rating"
    t.string   "desc_code"
    t.string   "rev_gaz_ref"
    t.string   "rev_treaty_legislation"
    t.integer  "createdBy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "WKT",                    limit: {:srid=>4326, :type=>"multi_polygon"}
  end

  create_table "islands", force: true do |t|
    t.integer  "name_id"
    t.string   "name"
    t.string   "status"
    t.integer  "feat_id"
    t.string   "feat_type"
    t.string   "nzgb_ref"
    t.string   "land_district"
    t.string   "crd_projection"
    t.float    "crd_north"
    t.float    "crd_east"
    t.string   "crd_datum"
    t.float    "crd_latitude"
    t.float    "crd_longitude"
    t.text     "info_ref"
    t.text     "info_origin"
    t.text     "info_description"
    t.text     "info_note"
    t.text     "feat_note"
    t.string   "maori_name"
    t.text     "cpa_legislation"
    t.string   "conservancy"
    t.string   "doc_cons_unit_no"
    t.string   "doc_gaz_ref"
    t.string   "treaty_legislation"
    t.string   "geom_type"
    t.string   "accuracy"
    t.string   "gebco"
    t.string   "region"
    t.string   "scufn"
    t.string   "height"
    t.string   "ant_pn_ref"
    t.string   "ant_pgaz_ref"
    t.string   "scar_id"
    t.string   "scar_rec_by"
    t.string   "accuracy_rating"
    t.string   "desc_code"
    t.string   "rev_gaz_ref"
    t.string   "rev_treaty_legislation"
    t.float    "ref_point_X"
    t.float    "ref_point_Y"
    t.integer  "createdBy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "WKT",                    limit: {:srid=>4326, :type=>"point"}
    t.boolean  "is_active",                                                            default: true
    t.string   "general_link"
    t.string   "code"
    t.spatial  "boundary",               limit: {:srid=>4326, :type=>"multi_polygon"}
    t.string   "dist_code"
  end

  create_table "items", force: true do |t|
    t.integer  "topic_id"
    t.string   "item_type"
    t.integer  "item_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "legal_roads", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "boundary",   limit: {:srid=>4326, :type=>"multi_polygon"}
  end

  create_table "lighthouses", force: true do |t|
    t.string   "t50_fid"
    t.string   "loc_type"
    t.string   "status"
    t.string   "str_type"
    t.string   "name"
    t.string   "code"
    t.string   "region"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "location",   limit: {:srid=>4326, :type=>"point"}
    t.integer  "mnz_id"
  end

  create_table "logs", force: true do |t|
    t.string   "callsign1"
    t.integer  "user1_id"
    t.integer  "power1"
    t.string   "signal1"
    t.string   "transceiver1"
    t.string   "antenna1"
    t.string   "comments1"
    t.boolean  "first_contact1",                                       default: true
    t.string   "loc_desc1"
    t.integer  "x1"
    t.integer  "y1"
    t.integer  "altitude1"
    t.datetime "date"
    t.datetime "time"
    t.string   "timezone"
    t.float    "frequency"
    t.string   "mode"
    t.boolean  "is_active",                                            default: true
    t.integer  "createdBy_id"
    t.boolean  "is_qrp1"
    t.boolean  "is_portable1"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "location1",      limit: {:srid=>4326, :type=>"point"}
    t.string   "asset_codes",                                          default: [],   array: true
    t.integer  "user_id"
    t.boolean  "do_not_lookup"
  end

  create_table "maplayers", force: true do |t|
    t.string   "name"
    t.string   "baseurl"
    t.string   "basemap"
    t.integer  "maxzoom"
    t.integer  "minzoom"
    t.string   "imagetype"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "nz_tribal_lands", primary_key: "ogc_fid", force: true do |t|
    t.spatial "wkb_geometry", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.decimal "id",                                                         precision: 10, scale: 0
    t.string  "name",         limit: 80
  end

  add_index "nz_tribal_lands", ["wkb_geometry"], :name => "nz_tribal_lands_wkb_geometry_geom_idx", :spatial => true

  create_table "parks", force: true do |t|
    t.string   "name"
    t.string   "doc_link"
    t.string   "tramper_link"
    t.string   "general_link"
    t.text     "description"
    t.boolean  "is_active",                                                   default: true
    t.integer  "createdBy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "boundary",      limit: {:srid=>4326, :type=>"multi_polygon"}
    t.boolean  "is_mr"
    t.string   "owner"
    t.spatial  "location",      limit: {:srid=>4326, :type=>"point"}
    t.string   "code"
    t.integer  "master_id"
    t.string   "dist_code"
    t.string   "land_district"
    t.string   "region"
  end

  create_table "places", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "posts", force: true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "filename"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.boolean  "do_not_publish"
    t.datetime "referenced_datetime"
    t.datetime "referenced_date"
    t.datetime "referenced_time"
    t.integer  "duration"
    t.string   "site"
    t.string   "code"
    t.string   "mode"
    t.string   "freq"
    t.boolean  "is_hut"
    t.boolean  "is_park"
    t.boolean  "is_island"
    t.boolean  "is_summit"
    t.string   "hut"
    t.string   "park"
    t.string   "island"
    t.string   "summit"
    t.string   "callsign"
    t.string   "asset_codes",         default: [], array: true
    t.integer  "user_id"
    t.boolean  "do_not_lookup"
  end

  create_table "pota_parks", force: true do |t|
    t.string   "reference"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "location",   limit: {:srid=>4326, :type=>"point"}
    t.integer  "park_id"
  end

  create_table "projections", force: true do |t|
    t.string   "name"
    t.string   "proj4"
    t.string   "wkt"
    t.integer  "epsg"
    t.integer  "createdBy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "regions", force: true do |t|
    t.string   "regc_code"
    t.string   "sota_code"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "boundary",                  limit: {:srid=>4326, :type=>"multi_polygon"}
    t.spatial  "boundary_quite_simplified", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.spatial  "boundary_simplified",       limit: {:srid=>4326, :type=>"multi_polygon"}
    t.spatial  "boundary_very_simplified",  limit: {:srid=>4326, :type=>"multi_polygon"}
  end

  create_table "roads", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "linestring", limit: {:srid=>4326, :type=>"multi_line_string"}
  end

  create_table "sessions", force: true do |t|
    t.text     "session_id"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id", :unique => true
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "sota_activations", force: true do |t|
    t.string   "callsign"
    t.string   "summit_code"
    t.integer  "summit_sota_id"
    t.date     "date"
    t.integer  "qso_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "sota_activation_id"
  end

  create_table "sota_chases", force: true do |t|
    t.string   "callsign"
    t.string   "summit_code"
    t.integer  "summit_sota_id"
    t.integer  "user_id"
    t.integer  "sota_activation_id"
    t.string   "band"
    t.string   "mode"
    t.date     "date"
    t.time     "time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sota_peaks", force: true do |t|
    t.string   "summit_code"
    t.string   "name"
    t.string   "short_code"
    t.string   "alt"
    t.integer  "points"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "location",    limit: {:srid=>4326, :type=>"point"}
    t.datetime "valid_from"
    t.datetime "valid_to"
  end

  create_table "sota_regions", force: true do |t|
    t.string   "dxcc"
    t.string   "region"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "timezones", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "difference"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "topics", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "owner_id"
    t.boolean  "is_public"
    t.boolean  "is_owners"
    t.datetime "last_updated"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_members_only"
    t.boolean  "date_required"
    t.boolean  "allow_mail"
    t.boolean  "duration_required"
    t.boolean  "is_alert"
    t.boolean  "is_spot"
    t.boolean  "allow_attachments"
  end

  create_table "uploads", force: true do |t|
    t.string   "doc_file_name"
    t.string   "doc_content_type"
    t.integer  "doc_file_size"
    t.datetime "doc_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "doc_callsign"
    t.boolean  "doc_no_create"
    t.boolean  "doc_ignore_error"
    t.string   "doc_location"
  end

  create_table "user_callsigns", force: true do |t|
    t.integer  "user_id"
    t.string   "callsign"
    t.datetime "from_date"
    t.datetime "to_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_topic_links", force: true do |t|
    t.integer  "user_id"
    t.integer  "topic_id"
    t.boolean  "mail"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "callsign"
    t.string   "email"
    t.string   "firstname"
    t.string   "lastname"
    t.string   "password_digest"
    t.string   "remember_token"
    t.string   "activation_digest"
    t.boolean  "activated",             default: false
    t.datetime "activated_at"
    t.boolean  "is_admin",              default: false
    t.boolean  "is_active",             default: true
    t.boolean  "is_modifier",           default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reset_digest"
    t.datetime "reset_sent_at"
    t.integer  "timezone"
    t.boolean  "membership_requested"
    t.boolean  "membership_confirmed"
    t.string   "home_qth"
    t.string   "mailuser"
    t.boolean  "group_admin"
    t.string   "remember_token2"
    t.string   "score"
    t.string   "score_total"
    t.string   "activated_count"
    t.string   "activated_count_total"
    t.string   "chased_count"
    t.string   "chased_count_total"
    t.boolean  "outstanding"
    t.string   "pin"
    t.boolean  "allow_pnp_login"
    t.datetime "hide_news_at"
    t.boolean  "read_only"
    t.string   "acctnumber"
    t.boolean  "logs_pota"
    t.boolean  "logs_wwff"
  end

  add_index "users", ["callsign"], :name => "index_users_on_callsign"
  add_index "users", ["remember_token"], :name => "index_users_on_remember_token"

  create_table "vk_assets", force: true do |t|
    t.string   "award"
    t.string   "wwff_code"
    t.string   "pota_code"
    t.string   "shire_code"
    t.string   "state"
    t.string   "region"
    t.string   "district"
    t.string   "code"
    t.string   "name"
    t.string   "site_type"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "location",   limit: {:srid=>4326, :type=>"point"}
  end

  add_index "vk_assets", ["award"], :name => "vk_award_indx"
  add_index "vk_assets", ["code"], :name => "vk_code_indx"

  create_table "web_link_classes", force: true do |t|
    t.string   "name"
    t.string   "display_name"
    t.string   "url"
    t.boolean  "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "wwff_parks", force: true do |t|
    t.string   "code"
    t.string   "name"
    t.string   "dxcc"
    t.string   "region"
    t.string   "notes"
    t.integer  "napalis_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "location",   limit: {:srid=>4326, :type=>"point"}
  end

end
