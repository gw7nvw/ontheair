# typed: false
require "test_helper"
include ApplicationHelper
class ApiSpotsTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/assets
  ##################################################################
  test "Should get api/alerts spots index" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    t1 = 2.minutes.ago
    t2 = 1.minute.ago

    item1=create_test_spot(user1, asset_codes: [asset1.code, asset2.code], callsign: user2.callsign, freq: 7.09, mode: "SSB", referenced_time: t1, referenced_date: t1, description: "test spot")
    item2=create_test_spot(user1, asset_codes: [asset3.code], callsign: user1.callsign, freq: 7.09, mode: "SSB", referenced_time: t2, referenced_date: t2, description: "self spot")

    get "/api/spots.json"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by { |d| d["reference"] }
    assert_equal data.count, 3
    assert_equal data[0].excluding(["id", "created_time"]), 
      {"comments" => "test spot", "referenced_time" => t1.iso8601(3), "name" => "#{asset1.name} [#{asset1.code}] {RE44nt}; #{asset2.name} [#{asset2.code}] {RE44nt}", "reference" => asset1.code, "frequency" => "7090.0", "mode" => "SSB", "activator" => user2.callsign, "spotter" => user1.callsign},
      "first row should match"
    assert_equal data[1].excluding(["id", "created_time"]), 
      {"comments" => "test spot", "referenced_time" => t1.iso8601(3), "name" => "#{asset1.name} [#{asset1.code}] {RE44nt}; #{asset2.name} [#{asset2.code}] {RE44nt}", "reference" => asset2.code, "frequency" => "7090.0", "mode" => "SSB", "activator" => user2.callsign, "spotter" => user1.callsign},
      "second row should match"
    assert_equal data[2].excluding(["id", "created_time"]),
      {"comments" => "self spot", "referenced_time" => t2.iso8601(3), "name" => "#{asset3.name} [#{asset3.code}] {RE44bt}", "reference" => asset3.code, "frequency" => "7090.0", "mode" => "SSB", "activator" => user1.callsign, "spotter" => user1.callsign},
      "last row should match"
  end

  test "Should not get api/spots index for external spots" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    t1 = 2.minutes.ago
    t2 = 1.minute.ago

    es1=create_test_external_spot(user1, code: 'GFF-0001', activatorCallsign: 'MM0FMF', frequency: "7.19", mode: "AM", spot_type: "WWFF", time: 2.minutes.ago)
    es2=create_test_external_spot(user1, code: asset1.code, activatorCallsign: user2.callsign, frequency: "7.09", mode: "SSB", spot_type: "ZLOTA")

    get "/api/spots.json"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 0
  end

  test "Should get api/alerts index for only zlota alerts" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'pota park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'NZ-0')
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    t1 = 2.minutes.ago
    t2 = 1.minute.ago

    item1=create_test_spot(user1, asset_codes: [asset1.code, asset2.code], callsign: user2.callsign, freq: 7.09, mode: "SSB", referenced_time: t1, referenced_date: t1, description: "test spot")
    item2=create_test_spot(user1, asset_codes: [asset3.code], callsign: user1.callsign, freq: 7.09, mode: "SSB", referenced_time: t2, referenced_date: t2, description: "self spot")

    get "/api/spots.json?zlota_only=true"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by{ |d| d["reference"] }
    assert_equal data.count, 2
    assert_equal data[0].excluding(["id", "created_time"]), 
      {"comments" => "test spot", "referenced_time" => t1.iso8601(3), "name" => "#{asset1.name} [#{asset1.code}] {RE44nt}; #{asset2.name} [#{asset2.code}] {RE44nt}", "reference" => asset1.code, "frequency" => "7090.0", "mode" => "SSB", "activator" => user2.callsign, "spotter" => user1.callsign},
      "first row should match"
    assert_equal data[1].excluding(["id", "created_time"]),
      {"comments" => "self spot", "referenced_time" => t2.iso8601(3), "name" => "#{asset3.name} [#{asset3.code}] {RE44bt}", "reference" => asset3.code, "frequency" => "7090.0", "mode" => "SSB", "activator" => user1.callsign, "spotter" => user1.callsign},
      "last row should match"
  end

  test "Should get api/spots only updated spots" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'pota park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'NZ-0')
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    t1 = 20.minutes.ago
    t2 = 1.minute.ago
    item1=create_test_spot(user1, asset_codes: [asset1.code, asset2.code], callsign: user2.callsign, freq: 7.09, mode: "SSB", referenced_time: t1, referenced_date: t1, description: "test spot")
    item2=create_test_spot(user1, asset_codes: [asset3.code], callsign: user1.callsign, freq: 7.09, mode: "SSB", referenced_time: t2, referenced_date: t2, description: "self spot")

    item1.update_column(:updated_at, 20.minutes.ago)
    item1.post.update_column(:updated_at, 20.minutes.ago)

    get "/api/spots.json?start_time=#{10.minutes.ago.strftime("%Y-%m-%d %H:%M")}"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 1
    assert_equal data[0].excluding(["id", "created_time"]),
      {"comments" => "self spot", "referenced_time" => t2.iso8601(3), "name" => "#{asset3.name} [#{asset3.code}] {RE44bt}", "reference" => asset3.code, "frequency" => "7090.0", "mode" => "SSB", "activator" => user1.callsign, "spotter" => user1.callsign},
      "last row should match"
  end
 
end
