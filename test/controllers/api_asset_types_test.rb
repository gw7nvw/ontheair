# typed: false
require "test_helper"
include ApplicationHelper
class ApiAssetTypesTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/assets
  ##################################################################
  test "Should get api/assettypes index" do

    get "/api/assettypes.json"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 11
    assert_equal data.first.excluding(["id", "created_at", "updated_at"]), 
      {"name" => "lake", "table_name" => "Lake", "has_location" => true, "has_boundary" => true, "index_name" => "code", "display_name" => "Lake", "fields" => "info_origin", "pnp_class" => "ZLOTA", "keep_score" => true, "min_qso" => 2, "has_elevation" => nil, "ele_buffer" => nil, "dist_buffer" => 500, "is_zlota" => true, "use_volcanic_field" => nil, "use_az" => nil, "use_within_sight" => nil, "like_pattern" => nil},
      "first row should match"
    assert_equal data.last.excluding(["id", "created_at", "updated_at"]), 
      {"name" => "llota lake", "table_name" => "", "has_location" => true, "has_boundary" => true, "index_name" => "code", "display_name" => "LLOTA LLake", "fields" => "", "pnp_class" => "LLOTA", "keep_score" => false, "min_qso" => 10, "has_elevation" => nil, "ele_buffer" => nil, "dist_buffer" => nil, "is_zlota" => false, "use_volcanic_field" => nil, "use_az" => nil, "use_within_sight" => nil, "like_pattern" => nil},
      "last row should match"
  end
end
