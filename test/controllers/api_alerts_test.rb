# typed: false
require "test_helper"
include ApplicationHelper
class ApiAlertsTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/assets
  ##################################################################
  test "Should get api/alerts index" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    t1 = 1.day.from_now.floor
    t2 = 2.days.from_now.floor

    item1=create_test_alert(user2, asset_codes: [asset1.code, asset2.code], callsign: user2.callsign, referenced_time: t1, freq: 7.09, mode: "SSB", duration: 1, description: "This is a comment")
    item2=create_test_alert(user1, asset_codes: [asset3.code], callsign: user1.callsign, referenced_time: t2, freq: 7.09, mode: "SSB", duration: 1, description: "This is a comment", do_not_lookup: true)

    get "/api/alerts.json"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by { |d| d["reference"] }
    assert_equal data.count, 3
    assert_equal data[0].excluding(["id", "created_time"]), 
      {"comments" => "This is a comment", "referenced_time" => t1.iso8601(3), "duration" => 1, "name" => "#{asset1.name} [#{asset1.code}] {RE44nt}; #{asset2.name} [#{asset2.code}] {RE44nt}", "reference" => asset1.code, "frequency" => "7090.0", "mode" => "SSB", "activator" => user2.callsign},
      "first row should match"
    assert_equal data[1].excluding(["id", "created_time"]), 
      {"comments" => "This is a comment", "referenced_time" => t1.iso8601(3), "duration" => 1, "name" => "#{asset1.name} [#{asset1.code}] {RE44nt}; #{asset2.name} [#{asset2.code}] {RE44nt}", "reference" => asset2.code, "frequency" => "7090.0", "mode" => "SSB", "activator" => user2.callsign},
      "second row should match"
    assert_equal data[2].excluding(["id", "created_time"]),
      {"comments" => "This is a comment", "referenced_time" => t2.iso8601(3), "duration" => 1, "name" => "#{asset3.name} [#{asset3.code}] {RE44bt}", "reference" => asset3.code, "frequency" => "7090.0", "mode" => "SSB", "activator" => user1.callsign},
      "last row should match"
  end

  test "Should get api/alerts index for only zlota alerts" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'pota park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'NZ-0')
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    t1 = 1.day.from_now.floor
    t2 = 2.days.from_now.floor

    item1=create_test_alert(user2, asset_codes: [asset1.code, asset2.code], callsign: user2.callsign, referenced_time: t1, freq: 7.09, mode: "SSB", duration: 1, description: "This is a comment")
    item2=create_test_alert(user1, asset_codes: [asset3.code], callsign: user1.callsign, referenced_time: t2, freq: 7.09, mode: "SSB", duration: 1, description: "This is a comment", do_not_lookup: true)

    get "/api/alerts.json?zlota_only=true"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by{ |d| d["reference"]}
    assert_equal data.count, 2
    assert_equal data[0].excluding(["id", "created_time"]),
      {"comments" => "This is a comment", "referenced_time" => t1.iso8601(3), "duration" => 1, "name" => "#{asset1.name} [#{asset1.code}] {RE44nt}; #{asset2.name} [#{asset2.code}] {RE44nt}", "reference" => asset1.code, "frequency" => "7090.0", "mode" => "SSB", "activator" => user2.callsign},
      "first row should match"
    assert_equal data[1].excluding(["id", "created_time"]),
      {"comments" => "This is a comment", "referenced_time" => t2.iso8601(3), "duration" => 1, "name" => "#{asset3.name} [#{asset3.code}] {RE44bt}", "reference" => asset3.code, "frequency" => "7090.0", "mode" => "SSB", "activator" => user1.callsign},
      "last row should match"
  end

  test "Should get api/alerts only updated alerts" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'pota park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'NZ-0')
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    t1 = 1.day.from_now.floor
    t2 = 2.days.from_now.floor

    item1=create_test_alert(user2, asset_codes: [asset1.code, asset2.code], callsign: user2.callsign, referenced_time: t1, freq: 7.09, mode: "SSB", duration: 1, description: "This is a comment")
    item2=create_test_alert(user1, asset_codes: [asset3.code], callsign: user1.callsign, referenced_time: t2, freq: 7.09, mode: "SSB", duration: 1, description: "This is a comment", do_not_lookup: true)
    item1.update_column(:created_at, 20.minutes.ago)
    item1.post.update_column(:created_at, 20.minutes.ago)
    item1.update_column(:updated_at, 20.minutes.ago)
    item1.post.update_column(:updated_at, 20.minutes.ago)

    get "/api/alerts.json?start_time=#{10.minutes.ago.strftime("%Y-%m-%d %H:%M")}"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 1
    assert_equal data[0].excluding(["id", "created_time"]),
      {"comments" => "This is a comment", "referenced_time" => t2.iso8601(3), "duration" => 1, "name" => "#{asset3.name} [#{asset3.code}] {RE44bt}", "reference" => asset3.code, "frequency" => "7090.0", "mode" => "SSB", "activator" => user1.callsign},
      "row should match"
  end
 
end
