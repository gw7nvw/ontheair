# typed: false
require "test_helper"
include ApplicationHelper
class ApiAssetLinksTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/assets
  ##################################################################
  test "Should get api/assetlinks for all assets" do
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.2)

    get "/api/assetlinks.json"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 3
    assert_equal data[0].excluding(["id", "created_at", "updated_at"]), 
      {"contained_code" => "ZLH/OT-001", "containing_code" => "ZLP/OT-0001", "overlap" => nil},
      "first row should match"
    assert_equal data[1].excluding(["id", "created_at", "updated_at"]), 
      {"contained_code" => "ZLH/OT-001", "containing_code" => "ZLP/OT-0002", "overlap" => nil},
      "first row should match"
    assert_equal data[2].excluding(["id", "created_at", "updated_at"]), 
      {"contained_code" => "ZLP/OT-0001", "containing_code" => "ZLP/OT-0002", "overlap" => nil},
      "first row should match"
  end

  test "Should get api/assetlinks containing assets for single asset" do
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.2)

    get "/api/assetlinks.json?id=#{asset2.safecode}"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 1
    assert_equal data[0].excluding(["id", "created_at", "updated_at"]),
      {"contained_code" => "ZLP/OT-0001", "containing_code" => "ZLP/OT-0002", "overlap" => nil},
      "first row should match"
  end

  test "Should get api/assetlinks contained_by assets for single asset" do
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.2)

    get "/api/assetlinks.json?id=#{asset2.safecode}&contained_by_assets=true"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 1
    assert_equal data[0].excluding(["id", "created_at", "updated_at"]),
      {"contained_code" => "ZLH/OT-001", "containing_code" => "ZLP/OT-0001", "overlap" => nil},
      "first row should match"
  end
end
