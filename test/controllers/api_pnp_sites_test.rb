# typed: false
require "test_helper"
include ApplicationHelper
class ApiPnpSitesTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/SITES
  ##################################################################
  test "Should get api/SITES by class" do
    hut=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    park=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)
    pota=create_test_asset(asset_type: 'pota park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'NZ-0')
    wwff=create_test_asset(asset_type: 'wwff park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'ZLFF-0')

    get "/api/SITES/zlota"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by { |d| d["ID"] }
    assert_equal data.count, 2
    assert_equal data[0],
      {"ID" => hut.code, "Name" => hut.name, "Award" => "ZLOTA", "Class" => "HUT", "State" => nil, "POTAID" => pota.code, "ParkID" => wwff.code, "WWFFID" => wwff.code, "Region" => "OT", "Country" => "ZL", "ShireID" => nil, "Contains" => [], "District" => nil, "Latitude" => "-45.2000", "Location" => hut.code, "Continent" => "OC", "Longitude" => "169.1000", "ContainedBy" => [[pota.code, "POTA"], [wwff.code, "WWFF"], [park.code, "ZLOTA"]], "EquivalentTo" => []},
      "Hut should match"
    assert_equal data[1].excluding(["id", "created_at", "updated_at"]), 
      {"ID" => park.code, "Name" => park.name, "Award" => "ZLOTA", "Class" => "PARK", "State" => nil, "POTAID" => pota.code, "ParkID" => wwff.code, "WWFFID" => wwff.code, "Region" => "OT", "Country" => "ZL", "ShireID" => nil, "Contains" => [[pota.code, "POTA"], [wwff.code, "WWFF"], [hut.code, "ZLOTA"]], "District" => nil, "Latitude" => "-45.2000", "Location" => park.code, "Continent" => "OC", "Longitude" => "169.1000", "ContainedBy" => [[pota.code, "POTA"], [wwff.code, "WWFF"]], "EquivalentTo" => [[pota.code, "POTA"], [wwff.code, "WWFF"]]},
      "Park1 should match"
  end

  test "Should get api/SITES/SHIRES" do
    get "/api/SITES/SHIRES"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by { |d| d["ID"] }
    assert_equal data.count, 4
    assert_equal data[0],
      {"Award" => "Shires", "Location" => nil, "ID" => "ZL-CC1", "Name" => "Christchurch", "Longitude" => "172", "Latitude" => "-40.5", "ShireID" => "ZL-CC1", "ContainedBy" => nil, "Contains" => nil, "Region" => "CB", "Continent" => "OC", "Country" => "ZL", "District" => "ZL-CC1", "State" => nil, "Class" => "SHIRE"},
      "first row should match"
  end

  test "Should get api/SITES/IOTA" do
    get "/api/SITES/IOTA"

    data = JSON.parse(@response.body)
    expected_data = JSON.parse(IOTA_JSON)

    assert_equal data, expected_data, "Iota data should match"
  end
end
