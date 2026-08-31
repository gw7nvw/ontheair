# typed: false
require "test_helper"
include ApplicationHelper
class ApiAssetsTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/assets
  ##################################################################
  test "Should get api/assets index" do
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    get "/api/assets.json"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 3
    assert_equal data[0].excluding(["id", "created_at", "updated_at"]), 
      {"url" => "assets/#{asset1.safecode}", "asset_type" => "hut", "code" => asset1.code, "name" => asset1.name, "location" => "POINT (169.1 -45.2)", "altitude" => 1302, "minor" => false, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => nil}, 
      "Hut should match"
    assert_equal data[1].excluding(["id", "created_at", "updated_at"]), 
      {"url" => "assets/#{asset2.safecode}", "asset_type" => "park", "code" => asset2.code, "name" => asset2.name, "location" => "POINT (169.1 -45.2)", "altitude" => 1302, "minor" => false, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => 349285979.9796295}
      "Park1 should match"
    assert_equal data[2].excluding(["id", "created_at", "updated_at"]), 
      {"url" => "assets/#{asset3.safecode}", "asset_type" => "park", "code" => asset3.code, "name" => asset3.name, "location" => "POINT (168.1 -45.2)", "altitude" => 1401, "minor" => false, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => 1397139569.1267395}
      "Park2 should match"
  end

  test "Should get api/assets for single asset" do
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    get "/api/assets.json?code=#{asset1.safecode}"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 1
    assert_equal data[0].excluding(["id", "created_at", "updated_at"]), 
      {"url" => "assets/#{asset1.safecode}", "asset_type" => "hut", "code" => asset1.code, "name" => asset1.name, "location" => "POINT (169.1 -45.2)", "altitude" => 1302, "minor" => false, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => nil}, 
      "Hut should match"
  end

  test "Should get api/assets by type" do
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    get "/api/assets.json?asset_type=hut"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 1
    assert_equal data[0].excluding(["id", "created_at", "updated_at"]),
      {"url" => "assets/#{asset1.safecode}", "asset_type" => "hut", "code" => asset1.code, "name" => asset1.name, "location" => "POINT (169.1 -45.2)", "altitude" => 1302, "minor" => false, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => nil}, 
      "Hut should match"
  end


  test "Should get api/assets updates only" do
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset1.update_column(:updated_at, 365.days.ago)
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)
    asset2.update_column(:updated_at, 365.days.ago)
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    get "/api/assets.json?updated_since=#{1.week.ago.strftime("%Y-%m-%d")}"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 1
    assert_equal data[0].excluding(["id", "created_at", "updated_at"]),
      {"url" => "assets/#{asset3.safecode}", "asset_type" => "park", "code" => asset3.code, "name" => asset3.name, "location" => "POINT (168.1 -45.2)", "altitude" => 1401, "minor" => false, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => 1397139569.1267395}
      "Hut should match"
  end

  test "Can get api/assets active or all" do
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2), is_active: false)
    asset1.update_column(:updated_at, 365.days.ago)
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)
    asset2.update_column(:updated_at, 365.days.ago)
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    get "/api/assets.json"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 2
    assert_equal data[0].excluding(["id", "created_at", "updated_at"]), 
      {"url" => "assets/#{asset2.safecode}", "asset_type" => "park", "code" => asset2.code, "name" => asset2.name, "location" => "POINT (169.1 -45.2)", "altitude" => 1302, "minor" => false, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => 349285979.9796295}
      "Park1 should match"
    assert_equal data[1].excluding(["id", "created_at", "updated_at"]),
      {"url" => "assets/#{asset3.safecode}", "asset_type" => "park", "code" => asset3.code, "name" => asset3.name, "location" => "POINT (168.1 -45.2)", "altitude" => 1401, "minor" => false, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => 1397139569.1267395}
      "Hut should match"

    get "/api/assets.json?is_active=false"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 3
    assert_equal data[0].excluding(["id", "created_at", "updated_at"]), 
      {"url" => "assets/#{asset1.safecode}", "asset_type" => "hut", "code" => asset1.code, "name" => asset1.name, "location" => "POINT (169.1 -45.2)", "altitude" => 1302, "minor" => false, "is_active" => false, "region" => "OT", "old_code" => "invalid", "area" => nil}, 
      "Hut should match"
    assert_equal data[1].excluding(["id", "created_at", "updated_at"]), 
      {"url" => "assets/#{asset2.safecode}", "asset_type" => "park", "code" => asset2.code, "name" => asset2.name, "location" => "POINT (169.1 -45.2)", "altitude" => 1302, "minor" => false, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => 349285979.9796295}
      "Park1 should match"
    assert_equal data[2].excluding(["id", "created_at", "updated_at"]), 
      {"url" => "assets/#{asset3.safecode}", "asset_type" => "park", "code" => asset3.code, "name" => asset3.name, "location" => "POINT (168.1 -45.2)", "altitude" => 1401, "minor" => false, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => 1397139569.1267395}
      "Park2 should match"
  end

  test "Can get api/assets minor or all" do
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2), minor: true)
    asset1.update_column(:updated_at, 365.days.ago)
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)
    asset2.update_column(:updated_at, 365.days.ago)
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    get "/api/assets.json"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by { |d| d["code"] }
    assert_equal data.count, 2
    assert_equal data[0].excluding(["id", "created_at", "updated_at"]),
      {"url" => "assets/#{asset2.safecode}", "asset_type" => "park", "code" => asset2.code, "name" => asset2.name, "location" => "POINT (169.1 -45.2)", "altitude" => 1302, "minor" => false, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => 349285979.9796295}
      "Park1 should match"
    assert_equal data[1].excluding(["id", "created_at", "updated_at"]),
      {"url" => "assets/#{asset3.safecode}", "asset_type" => "park", "code" => asset3.code, "name" => asset3.name, "location" => "POINT (168.1 -45.2)", "altitude" => 1401, "minor" => false, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => 1397139569.1267395}
      "Hut should match"

    get "/api/assets.json?minor=true"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by {|d| d["code"] }
    assert_equal data.count, 3
    assert_equal data[0].excluding(["id", "created_at", "updated_at"]),
      {"url" => "assets/#{asset1.safecode}", "asset_type" => "hut", "code" => asset1.code, "name" => asset1.name, "location" => "POINT (169.1 -45.2)", "altitude" => 1302, "minor" => true, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => nil},
      "Hut should match"
    assert_equal data[1].excluding(["id", "created_at", "updated_at"]),
      {"url" => "assets/#{asset2.safecode}", "asset_type" => "park", "code" => asset2.code, "name" => asset2.name, "location" => "POINT (169.1 -45.2)", "altitude" => 1302, "minor" => false, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => 349285979.9796295}
      "Park1 should match"
    assert_equal data[2].excluding(["id", "created_at", "updated_at"]),
      {"url" => "assets/#{asset3.safecode}", "asset_type" => "park", "code" => asset3.code, "name" => asset3.name, "location" => "POINT (168.1 -45.2)", "altitude" => 1401, "minor" => false, "is_active" => true, "region" => "OT", "old_code" => "invalid", "area" => 1397139569.1267395}
      "Park2 should match"

  end

end
