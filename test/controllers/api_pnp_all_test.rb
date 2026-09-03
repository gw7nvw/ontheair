# typed: false
require "test_helper"
include ApplicationHelper
class ApiPnpAllTest < ActionDispatch::IntegrationTest


  ##################################################################
  # ONTHEAIR API
  ##################################################################
  ##################################################################
  # /api/ALL
  ##################################################################
  test "Should get api/ALL spots index" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1)
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    t1 = 2.minutes.ago.floor
    t2 = 1.minute.ago.floor

    item1=create_test_spot(user1, {asset_codes: [asset1.code, asset2.code], callsign: user2.callsign, freq: 7.09, mode: "SSB", referenced_time: t1, referenced_date: t1, description: "test spot"})

    item2=create_test_spot(user1, asset_codes: [asset3.code], callsign: user1.callsign, freq: 7.09, mode: "SSB", referenced_time: t2, referenced_date: t2, description: "self spot")

    get "/api/ALL.json"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by { |d| d["ID"] }
    assert_equal data.count, 2
    #note ID picking up LAST code, not first.  Not ideal, but too hard to fix for now ...
    assert_equal data[0].excluding(["actId"]), 
      {"ID" => asset2.code, "actFreq" => "7.09", "actMode" => "SSB","actTime" => t1.to_s,"actClass" => "ZLOTA","actSiteID" => asset2.code,"actSpoter" => user1.callsign,"actCallsign" => user2.callsign,"actComments" => "[#{asset1.code}, #{asset2.code}] test spot","actLocation" => asset2.code,"altLocation" => "#{asset1.name} [#{asset1.code}] {RE44nt}; #{asset2.name} [#{asset2.code}] {RE44nt}"},
      "first row should match"
    assert_equal data[1].excluding(["actId"]), 
      {"ID" => asset3.code, "actFreq" => "7.09", "actMode" => "SSB","actTime" => t2.to_s,"actClass" => "ZLOTA","actSiteID" => asset3.code,"actSpoter" => user1.callsign,"actCallsign" => user1.callsign,"actComments" => "self spot","actLocation" => asset3.code,"altLocation" => "#{asset3.name} [#{asset3.code}] {RE44bt}"},
      "second row should match"
  end

  test "Should get api/spots index for external spots" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    t1 = 2.minutes.ago
    t2 = 1.minute.ago

    es1=create_test_external_spot(user1, code: 'GFF-0001', activatorCallsign: 'MM0FMF', frequency: "7.19", mode: "AM", spot_type: "WWFF", time: t1)
    es2=create_test_external_spot(user1, code: asset1.code, activatorCallsign: user2.callsign, frequency: "7.09", mode: "SSB", spot_type: "ZLOTA", time: t2, comments: "cq cq")

    get "/api/ALL.json"

    assert_response :success

    data = JSON.parse(@response.body)
    data = data.sort_by { |d| d["ID"] }
    assert_equal 2, data.count
    assert_equal data[0].excluding(["actId"]), 
      {"ID" => "GFF-0001", "ParkID" => "GFF-0001", "WWFFID" => "GFF-0001", "WWFFid" => "GFF-0001", "actFreq" => "7.19", "actMode" => "AM", "actTime" => t1.to_s, "actClass" => "WWFF", "actSiteID" => "GFF-0001", "actSpoter" => user1.callsign, "actCallsign" => "MM0FMF", "actComments" => "", "actLocation" => "", "altLocation" => ""},
      "first row should match"
    assert_equal data[1].excluding(["actId"]), 
      {"ID" => asset1.code, "actFreq" => "7.09", "actMode" => "SSB", "actTime" => t2.to_s, "actClass" => "ZLOTA", "actSiteID" => asset1.code, "actSpoter" => user1.callsign, "actCallsign" => user2.callsign, "actComments" => "cq cq", "actLocation" => asset1.code, "altLocation" => ""},
      "second row should match"
  end

  test "Should be able to specify start_time" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut', region: 'OT', location: create_point(169.1,-45.2))
    asset2=create_test_asset(asset_type: 'pota park', region: 'OT', location: create_point(169.1,-45.2), test_radius: 0.1, code_prefix: 'NZ-0')
    asset3=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    t1 = 21.minutes.ago
    t2 = 1.minute.ago

    item1=create_test_spot(user1, asset_codes: [asset1.code, asset2.code], callsign: user2.callsign, freq: 7.09, mode: "SSB", referenced_time: t1, referenced_date: t1, description: "test spot")
    cs=ConsolidatedSpot.last
    cs.update_column(:updated_at, 21.minutes.ago)
    item2=create_test_spot(user1, asset_codes: [asset3.code], callsign: user1.callsign, freq: 7.09, mode: "SSB", referenced_time: t2, referenced_date: t2, description: "self spot")

    get "/api/ALL/10"
    data = JSON.parse(@response.body)

    assert_equal 1, data.count, "Expected only 1 result in 10-minute window"
    assert_equal data[0].excluding(["actId"]),
      {"ID" => asset3.code, "actFreq" => "7.09", "actMode" => "SSB","actTime" => t2.to_s,"actClass" => "ZLOTA","actSiteID" => asset3.code,"actSpoter" => user1.callsign,"actCallsign" => user1.callsign,"actComments" => "self spot","actLocation" => asset3.code,"altLocation" => "#{asset3.name} [#{asset3.code}] {RE44bt}"},
      "result row should match"
  end

  test "Can specify zone (continent)" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    t1 = 2.minutes.ago
    t2 = 1.minute.ago

    es1=create_test_external_spot(user1, code: 'GFF-0001', activatorCallsign: 'MM0FMF', frequency: "7.19", mode: "AM", spot_type: "WWFF", time: t1)
    sleep 1
    es2=create_test_external_spot(user1, code: asset1.code, activatorCallsign: user2.callsign, frequency: "7.09", mode: "SSB", spot_type: "ZLOTA", time: t2, comments: "cq cq")

    #specify as param
    get "/api/ALL?zone=OC"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 1
    assert_equal data[0].excluding(["actId"]),
      {"ID" => asset1.code, "actFreq" => "7.09", "actMode" => "SSB", "actTime" => t2.to_s, "actClass" => "ZLOTA", "actSiteID" => asset1.code, "actSpoter" => user1.callsign, "actCallsign" => user2.callsign, "actComments" => "cq cq", "actLocation" => asset1.code, "altLocation" => ""}
      "last row should match"

    #use URL alias
    get "/api/VK"

    assert_response :success

    data = JSON.parse(@response.body)
    assert_equal data.count, 1
    assert_equal data[0].excluding(["actId"]),
      {"ID" => asset1.code, "actFreq" => "7.09", "actMode" => "SSB", "actTime" => t2.to_s, "actClass" => "ZLOTA", "actSiteID" => asset1.code, "actSpoter" => user1.callsign, "actCallsign" => user2.callsign, "actComments" => "cq cq", "actLocation" => asset1.code, "altLocation" => ""}
      "last row should match"
  end

  test "can get epoch of latest spot" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'park', region: 'OT', location: create_point(168.1,-45.2), test_radius: 0.2)

    t1 = 2.minutes.ago
    t2 = 1.minute.ago

    es1=create_test_external_spot(user1, code: 'GFF-0001', activatorCallsign: 'MM0FMF', frequency: "7.19", mode: "AM", spot_type: "WWFF", time: t1)
    sleep 1
    es2=create_test_external_spot(user1, code: asset1.code, activatorCallsign: user2.callsign, frequency: "7.09", mode: "SSB", spot_type: "ZLOTA", time: t2, comments: "cq cq")

    
    #use URL alias
    get "/api/CHECK/SPOTS"

    assert_response :success
    data = JSON.parse(@response.body)
 assert_equal ConsolidatedSpot.last.updated_at.to_i, data.first["ActivationsLastUpdate"]

  end
end
